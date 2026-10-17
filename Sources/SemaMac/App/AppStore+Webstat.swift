// Gère la clé Webstat, l’actualisation des séries et le retour à la démonstration.
import Foundation
import MarketCore

extension AppStore {
    func checkWebstatKey() async {
        await checkMarketKeys()
        guard !didCheckWebstatKey else { return }
        didCheckWebstatKey = true
        do { hasWebstatKey = try await webstatKeychain.read() != nil }
        catch { webstatError = error.localizedDescription }
    }

    func requiredKey() async throws -> String {
        guard let key = try await webstatKeychain.read() else { hasWebstatKey = false; throw WebstatClient.ClientError.missingKey }
        return key
    }

    func connectWebstat(apiKey: String) async -> Bool {
        guard !isLoading, isSourceEnabled("webstat") else { return false }
        isLoading = true; webstatError = nil
        defer { isLoading = false }
        do {
            let generation = sourceGenerations["webstat"]
            let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let datasets = try await WebstatClient().datasets(apiKey: key)
            guard isSourceEnabled("webstat"), generation == sourceGenerations["webstat"] else { return false }
            try await webstatKeychain.save(key)
            hasWebstatKey = true; catalogueDatasets = datasets
            try storage.cacheCatalogue(.init(datasets: datasets, labels: catalogueLabels))
            await refresh(using: key)
            return true
        } catch {
            webstatError = "Connexion impossible : \(error.localizedDescription) Les données affichées sont conservées."
            return false
        }
    }

    func refreshSeries() async {
        guard !isLoading else { return }
        isLoading = true; webstatError = nil
        defer { isLoading = false }
        let key: String?
        do { key = try await webstatKeychain.read() }
        catch { webstatError = error.localizedDescription; await refresh(using: nil); return }
        await refresh(using: key)
    }

    private func refresh(using key: String?) async {
        var updated: [MarketSeries] = []; var failures: [String: String] = [:]
        var changedMeasurements: Set<String> = []
        let generations = sourceGenerations
        var blockedMarkets: [String: String] = [:]
        for id in preferences.followedSeriesIDs {
            let source = sourceID(for: id)
            guard isSourceEnabled(source), generations[source] == sourceGenerations[source] else { continue }
            if let blocked = blockedMarkets[source] { failures[id] = blocked; continue }
            do {
                try Task.checkCancellation()
                let old = series.first { $0.id == id && !$0.isDemo }
                let value: MarketSeries
                var measurementChanged = false
                if let instrument = old?.marketInstrument {
                    value = try await fetchMarket(instrument)
                } else if let descriptor = old?.statisticalDescriptor ?? statisticalDescriptors[id] {
                    let structure = try await StatisticalClient().structure(dataset: descriptor.dataset)
                    value = try await StatisticalClient().fetch(dataset: descriptor.dataset, structure: structure, key: descriptor.key)
                    measurementChanged = value.statisticalDescriptor.map { !descriptor.usesSameMeasurement(as: $0) } ?? true
                } else {
                    guard let key else { throw WebstatClient.ClientError.missingKey }
                    let descriptor = try await WebstatClient().descriptor(apiKey: key, key: id)
                    let resolved = await resolve(descriptor, apiKey: key)
                    value = try await fetchRecent(descriptor: resolved, apiKey: key)
                    measurementChanged = old?.descriptor.map { !$0.usesSameMeasurement(as: resolved) } ?? false
                }
                guard isSourceEnabled(source), generations[source] == sourceGenerations[source] else { continue }
                if measurementChanged {
                    changedMeasurements.insert(id)
                    failures[id] = "L’unité, l’échelle ou la base a changé. Les périodes récentes remplacent l’ancienne courbe ; rechargez l’historique et vérifiez les seuils."
                    updated.append(value)
                } else {
                    updated.append(value.replacing(observations: (old?.observations ?? []) + value.observations,
                        completeHistory: old?.hasCompleteHistory))
                }
            } catch is CancellationError { break }
            catch {
                if isSourceEnabled(source), generations[source] == sourceGenerations[source] {
                    failures[id] = error.localizedDescription
                    if MarketProvider(rawValue: source) != nil, let issue = error as? MarketDataError,
                       issue == .quota || issue == .invalidKey { blockedMarkets[source] = issue.localizedDescription }
                }
            }
        }
        updated.removeAll { !isSourceEnabled(for: $0.id) || generations[sourceID(for: $0.id)] != sourceGenerations[sourceID(for: $0.id)] }
        if !changedMeasurements.isEmpty {
            let paused = mutatePreferences { value in
                for index in value.alerts.indices where changedMeasurements.contains(value.alerts[index].seriesID) {
                    value.alerts[index].isEnabled = false
                }
            }
            // Keep the old descriptor too when pausing cannot be persisted. A later refresh
            // must detect the scale change again instead of resuming a stale threshold.
            if !paused {
                updated.removeAll { changedMeasurements.contains($0.id) }
                for id in changedMeasurements { failures[id] = "La source a changé d’unité, d’échelle ou de base. La sauvegarde des alertes en pause a échoué ; les anciennes données restent affichées." }
            }
        }
        seriesErrors = failures
        if !updated.isEmpty {
            merge(updated)
            hasLoadedWebstat = series.contains { !$0.isDemo && $0.sourceURL?.host == "webstat.banque-france.fr" }
            if let preview = previewDescriptor, let value = updated.first(where: { $0.id == preview.key }) {
                previewSeries = value; previewDescriptor = value.descriptor; previewError = nil
            }
            if let id = previewSeries?.id, previewDescriptor == nil, let value = updated.first(where: { $0.id == id }) {
                previewSeries = value; previewError = nil
            }
            do { try storage.cacheWebstat(series.filter { !$0.isDemo }) }
            catch { errorMessage = "Les repères sont chargés, mais leur sauvegarde locale a échoué." }
            evaluateAlerts(in: updated.filter { !changedMeasurements.contains($0.id) })
        }
        status = "\(updated.count) repères actualisés" + (failures.isEmpty ? " · alertes vérifiées." : " · \(failures.count) à vérifier.")
        webstatError = failures.keys.contains { id in sourceID(for: id) == "webstat" }
            ? "Certaines séries Webstat demandent une vérification. Consultez leur détail." : nil
    }

    func fetchRecent(descriptor: WebstatSeriesDescriptor, apiKey: String) async throws -> MarketSeries {
        let anchor = min(descriptor.lastPeriod ?? .now, .now)
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(byAdding: .year, value: -HistoryPeriod.recentYears, to: anchor)!
        let points = try await WebstatClient().observations(apiKey: apiKey, descriptor: descriptor, start: start)
        return descriptor.series(observations: points, syncedAt: .now,
            completeHistory: descriptor.firstPeriod.map { $0 >= start } ?? false)
    }

    func removeWebstatKey() async {
        guard !isLoading else { return }
        isLoading = true; defer { isLoading = false }
        do {
            try await webstatKeychain.remove(); hasWebstatKey = false
            cancelCatalogueSearch(); closePreview(); cancelHistory()
            status = "Clé Webstat retirée · les dernières données restent consultables localement."
        } catch { webstatError = error.localizedDescription }
    }

    func restoreDemo() {
        series = WebstatClient.starterSeries
        hasLoadedWebstat = false; reconcileSelection()
        status = "Données de démonstration · aucune valeur actuelle. Les séries en cache sont conservées sur disque."
    }
}
