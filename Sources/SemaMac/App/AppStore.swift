import Foundation
import Observation
import MarketCore

enum WorkspaceSection: String, CaseIterable, Identifiable {
    case overview, favorites, alerts, explorer
    var id: String { rawValue }
    var title: String {
        switch self { case .overview: "Panorama"; case .favorites: "Favoris"; case .alerts: "Alertes"; case .explorer: "Explorer" }
    }
    var symbol: String {
        switch self { case .overview: "square.grid.2x2"; case .favorites: "star"; case .alerts: "bell"; case .explorer: "globe.europe.africa" }
    }
}

@Observable @MainActor
final class AppStore {
    var series = WebstatClient.starterSeries
    var preferences = AppPreferences()
    var section: WorkspaceSection = .overview
    var category: SeriesCategory = .markets
    var selectedSeriesID = WebstatClient.canonicalID("eurusd")
    var period: HistoryPeriod = .month
    var isLoading = false
    var hasLoadedWebstat = false
    var hasWebstatKey = false
    var webstatError: String?
    var status: String?
    var errorMessage: String?
    var simulatedEvent: AlertEvent?
    var recentAlertEvents: [AlertEvent] = []
    var isAlertSheetPresented = false
    var isSearchPresented = false
    var isOnboardingPresented = false
    private var opensAlertAfterSearch = false
    var seriesErrors: [String: String] = [:]
    var historyLoadingID: String?
    var historyProgress: String?
    var catalogueSearch = WebstatSearch()
    var catalogueResults: [WebstatSeriesDescriptor] = []
    var catalogueTotal = 0
    var catalogueHasMore = false
    var isSearchingCatalogue = false
    var catalogueError: String?
    var catalogueDatasets: [WebstatDataset] = []
    var catalogueLabels: [String: [String: String]] = [:]
    var previewDescriptor: WebstatSeriesDescriptor?
    var previewSeries: MarketSeries?
    var isLoadingPreview = false
    var previewError: String?
    private let storage: LocalStorage
    private let notifications = NotificationService()
    private let webstatKeychain = WebstatKeychain()
    private var didCheckWebstatKey = false
    private var canSavePreferences = true
    private var searchTask: Task<Void, Never>?
    private var searchGeneration = UUID()
    private var summaryExportSearch: WebstatSearch?
    private var summaryExport: [WebstatSeriesDescriptor] = []
    private var previewTask: Task<Void, Never>?
    private var historyTask: Task<Void, Never>?
    private var historyGeneration = UUID()

    init(storage: LocalStorage = .applicationDefault()) {
        self.storage = storage
        do { preferences = try storage.preferences.load() }
        catch {
            canSavePreferences = false
            errorMessage = "Les réglages n’ont pas pu être lus. Le fichier existant est conservé : \(error.localizedDescription)"
        }
        do {
            let cached = try storage.cachedWebstat()
            if !cached.isEmpty {
                merge(cached.map { $0.withID(WebstatClient.canonicalID($0.id)) })
                hasLoadedWebstat = true
                status = "Repères Webstat conservés localement · consultez la période et la date de publication."
            } else {
                let previousRates = try storage.cachedRates()
                if !previousRates.isEmpty {
                    merge(previousRates.map { $0.withID(WebstatClient.canonicalID($0.id)) })
                    status = "Ancien cache BCE · connectez Webstat dans les réglages pour actualiser."
                }
            }
            if let catalog = try storage.cachedCatalogue() {
                catalogueDatasets = catalog.datasets
                catalogueLabels = catalog.labels
            }
        } catch { errorMessage = "Le cache des données est illisible. Il est conservé ; une actualisation pourra le remplacer." }
        reconcileSelection()
        isOnboardingPresented = canSavePreferences && preferences.onboardingCompleted != true
    }

    func beginOnboarding() {
        guard canSavePreferences else { return }
        isSearchPresented = false
        isAlertSheetPresented = false
        isOnboardingPresented = true
    }

    @discardableResult func finishOnboarding() -> Bool {
        var next = preferences
        next.onboardingCompleted = true
        guard commit(next) else { return false }
        isOnboardingPresented = false
        section = .overview
        return true
    }

    var starterSeries: [MarketSeries] { WebstatClient.starterSeries }
    var followedSeries: [MarketSeries] { preferences.followedSeriesIDs.compactMap { id in series.first { $0.id == id } } }
    var macroSeries: [MarketSeries] { followedSeries }
    var alertableSeries: [MarketSeries] { followedSeries.filter(\.canAlert) }
    var favorites: [MarketSeries] { followedSeries.filter { preferences.favoriteIDs.contains($0.id) } }
    var selectedSeries: MarketSeries? { followedSeries.first { $0.id == selectedSeriesID } ?? followedSeries.first }
    var originSummary: String { hasLoadedWebstat ? "Banque de France · Webstat" : "Webstat à connecter · démonstration disponible" }
    var macroAlerts: [AlertRule] { preferences.alerts.filter { $0.effectiveCondition == .level } }
    var palette: SemaPalette { SemaPalette(rawValue: preferences.themeID ?? "") ?? .teal }
    var canLoadMoreCatalogue: Bool { catalogueHasMore && !isSearchingCatalogue }
    var previewRequiresRefresh: Bool {
        guard let descriptor = previewDescriptor,
              let previous = followedSeries.first(where: { $0.id == descriptor.key })?.descriptor else { return false }
        return !previous.usesSameMeasurement(as: descriptor)
    }

    func setPalette(_ palette: SemaPalette) { mutatePreferences { $0.themeID = palette.rawValue } }
    func isFollowing(_ id: String) -> Bool { preferences.followedSeriesIDs.contains(WebstatClient.canonicalID(id)) }
    func isFavorite(_ id: String) -> Bool { preferences.favoriteIDs.contains(id) }
    func toggleFavorite(_ id: String) {
        guard isFollowing(id) else { return }
        mutatePreferences { value in
            if value.favoriteIDs.contains(id) { value.favoriteIDs.remove(id) } else { value.favoriteIDs.insert(id) }
        }
    }

    @discardableResult func followStarterSeries(ids: [String]) -> Bool {
        let allowed = Set(WebstatClient.starterIDs)
        var seen: Set<String> = []
        let chosen = ids.map(WebstatClient.canonicalID).filter { allowed.contains($0) && seen.insert($0).inserted }
        let result = mutatePreferences { value in
            value.followedSeriesIDs = chosen + value.followedSeriesIDs.filter { !allowed.contains($0) }
            for index in value.alerts.indices where allowed.contains(value.alerts[index].seriesID) && !chosen.contains(value.alerts[index].seriesID) {
                value.alerts[index].isEnabled = false
            }
            value.favoriteIDs = value.favoriteIDs.filter { chosen.contains($0) || !allowed.contains($0) }
        }
        if result { reconcileSelection() }
        return result
    }

    @discardableResult func follow(_ descriptor: WebstatSeriesDescriptor) async -> Bool {
        if isFollowing(descriptor.key) { return true }
        do {
            let value: MarketSeries
            if let previewSeries, previewSeries.id == descriptor.key { value = previewSeries }
            else { value = try await fetchRecent(descriptor: descriptor, apiKey: requiredKey()) }
            // Cache before preferences: failure never creates an apparently saved selection.
            let merged = series.filter { $0.id != value.id } + [value]
            try storage.cacheWebstat(merged.filter { !$0.isDemo })
            guard mutatePreferences({ $0.followedSeriesIDs.append(value.id) }) else { return false }
            merge([value]); hasLoadedWebstat = true
            if selectedSeries == nil { show(value) }
            return true
        } catch { previewError = error.localizedDescription; return false }
    }

    @discardableResult func unfollow(_ id: String) -> Bool {
        let result = mutatePreferences { value in
            value.followedSeriesIDs.removeAll { $0 == id }
            value.favoriteIDs.remove(id)
            for index in value.alerts.indices where value.alerts[index].seriesID == id { value.alerts[index].isEnabled = false }
        }
        if result { reconcileSelection() }
        return result
    }

    func moveFollowed(_ id: String, by offset: Int) {
        guard let index = preferences.followedSeriesIDs.firstIndex(of: id) else { return }
        let target = index + offset
        guard preferences.followedSeriesIDs.indices.contains(target) else { return }
        mutatePreferences { $0.followedSeriesIDs.swapAt(index, target) }
    }
    func moveFollowed(from offsets: IndexSet, to destination: Int) {
        var ids = preferences.followedSeriesIDs
        let moved = offsets.sorted().map { ids[$0] }
        for index in offsets.sorted(by: >) { ids.remove(at: index) }
        let target = destination - offsets.filter { $0 < destination }.count
        ids.insert(contentsOf: moved, at: min(max(0, target), ids.count))
        mutatePreferences { $0.followedSeriesIDs = ids }
    }

    func prepareAlert(for item: MarketSeries) {
        show(item); closePreview()
        if isSearchPresented { opensAlertAfterSearch = true; isSearchPresented = false }
        else { isAlertSheetPresented = true }
    }
    func finishSearch() {
        if opensAlertAfterSearch { opensAlertAfterSearch = false; isAlertSheetPresented = true }
    }

    func show(_ item: MarketSeries) {
        if let historyLoadingID, historyLoadingID != item.id { cancelHistory() }
        selectedSeriesID = item.id; category = item.category
        if !item.supports(period) { period = .all }
    }
    private func reconcileSelection() {
        if !followedSeries.contains(where: { $0.id == selectedSeriesID }) { selectedSeriesID = followedSeries.first?.id ?? "" }
    }

    func checkWebstatKey() async {
        guard !didCheckWebstatKey else { return }
        didCheckWebstatKey = true
        do { hasWebstatKey = try await webstatKeychain.read() != nil }
        catch { webstatError = error.localizedDescription }
    }
    private func requiredKey() async throws -> String {
        guard let key = try await webstatKeychain.read() else { hasWebstatKey = false; throw WebstatClient.ClientError.missingKey }
        return key
    }

    func connectWebstat(apiKey: String) async -> Bool {
        guard !isLoading else { return false }
        isLoading = true; webstatError = nil
        defer { isLoading = false }
        do {
            let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let datasets = try await WebstatClient().datasets(apiKey: key)
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
    func refreshWebstat() async {
        guard !isLoading else { return }
        isLoading = true; webstatError = nil
        defer { isLoading = false }
        do { await refresh(using: try await requiredKey()) }
        catch { webstatError = error.localizedDescription; status = webstatError }
    }
    private func refresh(using key: String) async {
        var updated: [MarketSeries] = []; var failures: [String: String] = [:]
        var changedMeasurements: Set<String> = []
        for id in preferences.followedSeriesIDs {
            do {
                try Task.checkCancellation()
                let descriptor = try await WebstatClient().descriptor(apiKey: key, key: id)
                let resolved = await resolve(descriptor, apiKey: key)
                let value = try await fetchRecent(descriptor: resolved, apiKey: key)
                let old = series.first { $0.id == id && !$0.isDemo }
                if let previous = old?.descriptor, !previous.usesSameMeasurement(as: resolved) {
                    changedMeasurements.insert(id)
                    failures[id] = "L’unité, l’échelle ou la base a changé. Les périodes récentes remplacent l’ancienne courbe ; rechargez l’historique et vérifiez les seuils."
                    updated.append(value)
                } else {
                    updated.append(value.replacing(observations: (old?.observations ?? []) + value.observations,
                        completeHistory: old?.hasCompleteHistory))
                }
            } catch is CancellationError { break }
            catch { failures[id] = error.localizedDescription }
        }
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
            merge(updated); hasLoadedWebstat = true
            if let preview = previewDescriptor, let value = updated.first(where: { $0.id == preview.key }) {
                previewSeries = value; previewDescriptor = value.descriptor; previewError = nil
            }
            do { try storage.cacheWebstat(series.filter { !$0.isDemo }) }
            catch { errorMessage = "Les repères sont chargés, mais leur sauvegarde locale a échoué." }
            evaluateAlerts(in: updated.filter { !changedMeasurements.contains($0.id) })
        }
        status = "\(updated.count) repères actualisés" + (failures.isEmpty ? " · alertes vérifiées." : " · \(failures.count) à vérifier.")
        webstatError = failures.isEmpty ? nil : "Certaines séries demandent une vérification. Consultez leur détail."
    }
    private func fetchRecent(descriptor: WebstatSeriesDescriptor, apiKey: String) async throws -> MarketSeries {
        let anchor = min(descriptor.lastPeriod ?? .now, .now)
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(byAdding: .year, value: -6, to: anchor)!
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

    func searchCatalogue(loadMore: Bool = false) {
        searchTask?.cancel()
        let generation = UUID(); searchGeneration = generation
        var search = catalogueSearch
        if let dataset = catalogueDatasets.first(where: { $0.id == search.datasetID }) { search.areaField = dataset.areaField ?? "ref_area" }
        let offset = loadMore ? catalogueResults.count : 0
        if summaryExportSearch != search { summaryExportSearch = nil; summaryExport = [] }
        if !loadMore { catalogueResults = []; catalogueTotal = 0; catalogueHasMore = false }
        catalogueError = nil
        guard hasWebstatKey else { isSearchingCatalogue = false; return }
        isSearchingCatalogue = true
        searchTask = Task {
            do {
                if !loadMore { try await Task.sleep(for: .milliseconds(250)) }
                let key = try await requiredKey()
                try Task.checkCancellation()
                guard generation == searchGeneration else { return }
                if catalogueDatasets.isEmpty { catalogueDatasets = try await WebstatClient().datasets(apiKey: key) }
                let areaList = catalogueDatasets.first(where: { $0.id == search.datasetID })?.areaCodelist ?? "CL_AREA"
                let missing = ["CL_UNIT", "CL_UNIT_MULT", "CL_FREQ", "CL_ORGANISATION", areaList].filter { catalogueLabels[$0] == nil }
                if !missing.isEmpty {
                    let labels = try await WebstatClient().codeLabels(apiKey: key, ids: missing)
                    try Task.checkCancellation()
                    guard generation == searchGeneration else { return }
                    catalogueLabels.merge(labels, uniquingKeysWith: { _, new in new })
                    try? storage.cacheCatalogue(.init(datasets: catalogueDatasets, labels: catalogueLabels))
                }
                let items: [WebstatSeriesDescriptor]
                let hasMore: Bool
                if offset >= 9_950 {
                    if summaryExportSearch != search {
                        let summaries = try await WebstatClient().exportSummaries(apiKey: key, search: search)
                        try Task.checkCancellation()
                        guard generation == searchGeneration else { return }
                        summaryExport = summaries; summaryExportSearch = search
                    }
                    let end = min(offset + 50, summaryExport.count)
                    items = offset < end ? Array(summaryExport[offset..<end]) : []
                    catalogueTotal = summaryExport.count
                    hasMore = end < summaryExport.count
                } else {
                    let page = try await WebstatClient().search(apiKey: key, search: search, offset: offset)
                    try Task.checkCancellation()
                    guard generation == searchGeneration else { return }
                    items = page.items
                    if !loadMore { catalogueTotal = page.total }
                    hasMore = page.hasMore
                }
                try Task.checkCancellation()
                guard generation == searchGeneration else { return }
                let resolvedItems = items.map { resolvedWithCachedLabels($0) }
                if loadMore {
                    let known = Set(catalogueResults.map(\.key)); catalogueResults += resolvedItems.filter { !known.contains($0.key) }
                } else { catalogueResults = resolvedItems }
                catalogueHasMore = hasMore
                isSearchingCatalogue = false
            } catch is CancellationError { }
            catch {
                guard generation == searchGeneration else { return }
                catalogueError = error.localizedDescription; isSearchingCatalogue = false
            }
        }
    }
    func cancelCatalogueSearch() { searchTask?.cancel(); searchGeneration = UUID(); isSearchingCatalogue = false }
    func openPreview(_ descriptor: WebstatSeriesDescriptor) {
        previewTask?.cancel(); previewDescriptor = descriptor
        previewSeries = series.first { $0.id == descriptor.key && !$0.isDemo }
        previewError = nil; isLoadingPreview = true
        previewTask = Task {
            do {
                let key = try await requiredKey()
                let official = try await WebstatClient().descriptor(apiKey: key, key: descriptor.key)
                let resolved = await resolve(official, apiKey: key)
                try Task.checkCancellation()
                guard previewDescriptor?.key == descriptor.key else { return }
                previewDescriptor = resolved
                let value = try await fetchRecent(descriptor: resolved, apiKey: key)
                try Task.checkCancellation()
                guard previewDescriptor?.key == descriptor.key else { return }
                previewDescriptor = resolved
                let compatible = previewSeries?.descriptor?.usesSameMeasurement(as: resolved) ?? true
                let existing = compatible ? previewSeries?.observations ?? [] : []
                previewSeries = value.replacing(observations: existing + value.observations,
                    completeHistory: compatible ? previewSeries?.hasCompleteHistory : false)
                if previewRequiresRefresh {
                    previewError = "La source a changé d’unité, d’échelle ou de base. Cet aperçu utilise les nouvelles valeurs ; actualisez vos repères avant de l’ouvrir."
                }
                isLoadingPreview = false
            } catch is CancellationError { }
            catch {
                guard previewDescriptor?.key == descriptor.key else { return }
                previewError = error.localizedDescription; isLoadingPreview = false
            }
        }
    }
    func closePreview() { previewTask?.cancel(); if historyLoadingID == previewDescriptor?.key { cancelHistory() }; previewDescriptor = nil; previewSeries = nil; previewError = nil; isLoadingPreview = false }
    private func resolvedWithCachedLabels(_ descriptor: WebstatSeriesDescriptor) -> WebstatSeriesDescriptor {
        var labels: [String: String] = [:]
        let dataset = catalogueDatasets.first { $0.id == descriptor.datasetID }
        let mapping = (dataset?.dimensionCodelists ?? [:]).merging(dataset?.attributeCodelists ?? [:], uniquingKeysWith: { _, attribute in attribute })
        let attributes = descriptor.attributes; let dimensions = descriptor.dimensions
        for (field, list) in mapping {
            let code = descriptor.raw[field.lowercased()]?.text ?? dimensions[field] ?? attributes[field]
            if let code, let label = catalogueLabels[list]?[code] { labels[field.lowercased()] = label }
        }
        let fallback = ["unit": "CL_UNIT", "unit_mult": "CL_UNIT_MULT", "freq": "CL_FREQ", "source_agency": "CL_ORGANISATION", "ref_area": "CL_AREA"]
        for (field, list) in fallback where labels[field] == nil {
            let code = descriptor.raw[field]?.text ?? dimensions[field.uppercased()] ?? attributes[field.uppercased()]
            if let code, let label = catalogueLabels[list]?[code] { labels[field] = label }
        }
        if labels["ref_area"] == nil { labels["ref_area"] = labels["ame_ref_area"] ?? labels["zone_geo"] }
        return descriptor.resolving(labels: labels)
    }
    private func resolve(_ descriptor: WebstatSeriesDescriptor, apiKey: String) async -> WebstatSeriesDescriptor {
        let dataset = catalogueDatasets.first { $0.id == descriptor.datasetID }
        let lists = Array((dataset?.dimensionCodelists ?? [:]).values) + Array((dataset?.attributeCodelists ?? [:]).values)
        let ids = Array(Set(lists + ["CL_UNIT", "CL_UNIT_MULT", "CL_FREQ", "CL_ORGANISATION", "CL_AREA"])).filter { catalogueLabels[$0] == nil }
        if !ids.isEmpty, let labels = try? await WebstatClient().codeLabels(apiKey: apiKey, ids: ids) {
            catalogueLabels.merge(labels, uniquingKeysWith: { _, new in new })
            try? storage.cacheCatalogue(.init(datasets: catalogueDatasets, labels: catalogueLabels))
        }
        return resolvedWithCachedLabels(descriptor)
    }

    func loadAllHistory(_ item: MarketSeries, reload: Bool = false) {
        guard !item.isDemo, let descriptor = item.descriptor else { return }
        historyTask?.cancel(); let generation = UUID(); historyGeneration = generation
        historyLoadingID = item.id; historyProgress = "Chargement des périodes anciennes…"
        historyTask = Task {
            defer { if historyGeneration == generation { historyLoadingID = nil; historyProgress = nil } }
            do {
                let key = try await requiredKey()
                let current = try await WebstatClient().descriptor(apiKey: key, key: descriptor.key)
                guard descriptor.usesSameMeasurement(as: current) else { throw WebstatClient.ClientError.metadataChanged }
                let descriptor = current.resolving(labels: descriptor.labels)
                guard let first = descriptor.firstObservationStart else { throw WebstatClient.ClientError.incompleteData }
                var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
                var end = reload ? min(descriptor.lastPeriod ?? .now, .now) : item.observations.first?.date ?? .now
                var points = reload ? [] : item.observations
                while end >= first {
                    try Task.checkCancellation()
                    let start = max(first, calendar.date(byAdding: .year, value: -6, to: end)!)
                    let older = try await WebstatClient().observations(apiKey: key, descriptor: descriptor, start: start, end: end)
                    points = older + points
                    try Task.checkCancellation()
                    let complete = start <= first
                    let value = descriptor.series(observations: points, syncedAt: .now, completeHistory: complete)
                    if isFollowing(item.id) {
                        merge([value]); try storage.cacheWebstat(series.filter { !$0.isDemo })
                    }
                    if previewDescriptor?.key == item.id { previewSeries = value }
                    historyProgress = "Historique reçu depuis \(MarketFormat.date(value.observations.first?.date))"
                    if complete { break }
                    end = start.addingTimeInterval(-86_400)
                }
            } catch is CancellationError { }
            catch { seriesErrors[item.id] = error.localizedDescription; if previewDescriptor?.key == item.id { previewError = error.localizedDescription } }
        }
    }
    func cancelHistory() { historyTask?.cancel(); historyGeneration = UUID(); historyLoadingID = nil; historyProgress = nil }

    func restoreDemo() {
        series = WebstatClient.starterSeries
        hasLoadedWebstat = false; reconcileSelection()
        status = "Données de démonstration · aucune valeur actuelle. Les séries en cache sont conservées sur disque."
    }

    func addAlert(seriesID: String, direction: AlertDirection, threshold: Decimal) -> Bool {
        guard let item = macroSeries.first(where: { $0.id == seriesID }), item.canAlert else { return false }
        let rule = AlertRule(seriesID: seriesID, direction: direction, threshold: threshold,
            condition: .level, lastEvaluatedAt: item.isDemo ? nil : item.latest?.date)
        guard rule.isValid, mutatePreferences({ $0.alerts.append(rule) }) else { return false }
        section = .alerts; return true
    }
    func toggleAlert(_ id: UUID) {
        guard let index = preferences.alerts.firstIndex(where: { $0.id == id }) else { return }
        let rule = preferences.alerts[index]
        let item = followedSeries.first { $0.id == rule.seriesID }
        guard rule.isEnabled || (item?.canAlert == true) else { return }
        mutatePreferences { value in
            value.alerts[index].isEnabled.toggle()
            if value.alerts[index].isEnabled { value.alerts[index].lastEvaluatedAt = item?.isDemo == false ? item?.latest?.date : nil }
        }
    }
    func deleteAlert(_ id: UUID) { mutatePreferences { $0.alerts.removeAll { $0.id == id } } }
    func simulate(_ rule: AlertRule) {
        guard let item = series.first(where: { $0.id == rule.seriesID }), item.canAlert else { return }
        let step = Decimal(string: "0.1")!; let sign: Decimal = rule.direction == .fall ? -1 : 1
        let sample = item.replacing(observations: [
            .init(date: Date().addingTimeInterval(-86_400), value: rule.threshold - sign * step),
            .init(date: Date(), value: rule.threshold + sign * step)])
        let active = AlertRule(id: rule.id, seriesID: rule.seriesID, direction: rule.direction, threshold: rule.threshold, condition: .level)
        if let event = AlertEvaluator.evaluate(active, series: sample) {
            simulatedEvent = AlertEvent(ruleID: event.ruleID, seriesID: event.seriesID, observedAt: event.observedAt,
                changePercent: event.changePercent, isDemo: true, observedValue: event.observedValue)
        }
        if preferences.notificationsEnabled {
            Task {
                do { try await notifications.send(title: item.name,
                    body: "Seuil de \(MarketFormat.number(rule.threshold, digits: item.fractionDigits)) \(item.displayUnit) franchi dans la démonstration.", isDemo: true) }
                catch { errorMessage = "La notification système n’a pas pu être envoyée : \(error.localizedDescription)" }
            }
        }
    }
    private func evaluateAlerts(in values: [MarketSeries]) {
        var events: [AlertEvent] = []; var next = preferences; var advanced = false
        for index in next.alerts.indices {
            let rule = next.alerts[index]
            guard rule.isEnabled, rule.effectiveCondition == .level,
                  let item = values.first(where: { $0.id == rule.seriesID }), !item.isDemo, item.canAlert,
                  let latest = item.latest, rule.lastEvaluatedAt.map({ latest.date > $0 }) ?? true else { continue }
            events += AlertEvaluator.newEvents(rule, series: item)
            next.alerts[index].lastEvaluatedAt = latest.date; advanced = true
        }
        guard advanced, commit(next) else { return }
        recentAlertEvents = Array((recentAlertEvents + events).suffix(20))
        guard preferences.notificationsEnabled, !events.isEmpty else { return }
        Task {
            for event in events {
                guard let item = values.first(where: { $0.id == event.seriesID }), let value = event.observedValue else { continue }
                do { try await notifications.send(title: item.name,
                    body: "Seuil franchi : \(MarketFormat.number(value, digits: item.fractionDigits)) \(item.displayUnit) · observation du \(MarketFormat.date(event.observedAt)).", isDemo: false) }
                catch { errorMessage = "La notification système n’a pas pu être envoyée : \(error.localizedDescription)" }
            }
        }
    }
    func setNotificationsEnabled(_ enabled: Bool) async {
        var next = preferences
        if enabled {
            do {
                next.notificationsEnabled = try await notifications.requestPermission()
                if !next.notificationsEnabled { errorMessage = "Les notifications ne sont pas autorisées dans les Réglages Système." }
            } catch { errorMessage = error.localizedDescription }
        } else { next.notificationsEnabled = false }
        commit(next)
    }
    private func merge(_ values: [MarketSeries]) {
        for value in values where value.category != .funds {
            if let index = series.firstIndex(where: { $0.id == value.id }) { series[index] = value } else { series.append(value) }
        }
    }
    @discardableResult private func mutatePreferences(_ change: (inout AppPreferences) -> Void) -> Bool {
        var next = preferences; change(&next); return commit(next)
    }
    @discardableResult func commit(_ next: AppPreferences) -> Bool {
        guard canSavePreferences else { errorMessage = "La sauvegarde est désactivée pour préserver le fichier de réglages illisible."; return false }
        do { try storage.preferences.save(next); preferences = next; return true }
        catch { errorMessage = "Les modifications n’ont pas été sauvegardées : \(error.localizedDescription)"; return false }
    }
}
