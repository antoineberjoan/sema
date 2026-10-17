// Coordonne les données, préférences et actions partagées par la fenêtre et le bandeau sur le MainActor.
import AppKit
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

enum SemaSettingsTab: Hashable { case general, sources, profile, appearance, shortcuts, about }

@Observable @MainActor
final class AppStore {
    var series = WebstatClient.starterSeries
    var preferences = AppPreferences()
    var section: WorkspaceSection = .overview
    var settingsTab: SemaSettingsTab = .general
    var category: SeriesCategory = .markets
    var selectedSeriesID = WebstatClient.canonicalID("eurusd")
    var period: HistoryPeriod = .year
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
    var shortcutError: String?
    let globalShortcuts = GlobalShortcuts()
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
    var statisticalPreviewRequest: String?
    private var previewSourceID: String?
    private var statisticalCatalogues: [String: [StatisticalDataset]] = [:]
    private var statisticalDescriptors: [String: StatisticalSeriesDescriptor] = [:]
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
    private var sourceGenerations: [String: UUID] = [:]
    @ObservationIgnored private var invertedExchangeRates: [String: (source: MarketSeries, display: MarketSeries)] = [:]

    init(storage: LocalStorage = .applicationDefault()) {
        self.storage = storage
        do { preferences = try storage.preferences.load() }
        catch {
            canSavePreferences = false
            errorMessage = "Les réglages n’ont pas pu être lus. Le fichier existant est conservé : \(error.localizedDescription)"
        }
        NSApplication.shared.appearance = appearance.nativeAppearance
        do {
            let cached = try storage.cachedWebstat()
            if !cached.isEmpty {
                merge(cached.map { $0.withID(WebstatClient.canonicalID($0.id)) })
                hasLoadedWebstat = cached.contains { $0.sourceURL?.host == "webstat.banque-france.fr" }
                status = "Repères conservés localement · consultez la période et la date de publication."
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
            statisticalCatalogues = try storage.cachedStatisticalCatalogues()
        } catch { errorMessage = "Le cache des données est illisible. Il est conservé ; une actualisation pourra le remplacer." }
        reconcileSelection()
        isOnboardingPresented = canSavePreferences && preferences.onboardingCompleted != true
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
    private var storedFollowedSeries: [MarketSeries] { preferences.followedSeriesIDs.compactMap { id in series.first { $0.id == id } } }
    var followedSeries: [MarketSeries] { SeriesEquivalence.unique(storedFollowedSeries) }
    var macroSeries: [MarketSeries] { followedSeries }
    var alertableSeries: [MarketSeries] { followedSeries.filter { $0.canAlert && isSourceEnabled(for: $0.id) } }
    var favorites: [MarketSeries] { followedSeries.filter { isFavorite($0.id) } }
    var selectedSeries: MarketSeries? { followedSeries.first { $0.id == selectedSeriesID } ?? followedSeries.first }
    var canRefresh: Bool {
        preferences.followedSeriesIDs.contains { isSourceEnabled(for: $0) && (hasWebstatKey || statisticalDescriptors[$0] != nil) }
    }
    func canLoadFullHistory(_ item: MarketSeries) -> Bool {
        !item.isDemo && isSourceEnabled(for: item.id) && (item.statisticalDescriptor != nil || (hasWebstatKey && item.descriptor?.firstPeriod != nil))
    }
    func statisticalDatasets(source: StatisticalSource, reload: Bool = false) async throws -> [StatisticalDataset] {
        guard isSourceEnabled(source.rawValue) else { throw CancellationError() }
        let generation = sourceGenerations[source.rawValue]
        if !reload, let cached = statisticalCatalogues[source.rawValue] { return cached }
        let datasets = try await StatisticalClient().datasets(source: source)
        try Task.checkCancellation()
        guard isSourceEnabled(source.rawValue), generation == sourceGenerations[source.rawValue] else { throw CancellationError() }
        statisticalCatalogues[source.rawValue] = datasets
        do { try storage.cacheStatisticalCatalogues(statisticalCatalogues) }
        catch { errorMessage = "Le catalogue est chargé, mais sa sauvegarde locale a échoué." }
        return datasets
    }
    var macroAlerts: [AlertRule] { preferences.alerts.filter { $0.effectiveCondition == .level } }
    var palette: SemaPalette { SemaPalette(rawValue: preferences.themeID ?? "") ?? .graphite }
    var appearance: SemaAppearance { SemaAppearance(rawValue: preferences.appearanceID ?? "") ?? .system }
    var ribbonPosition: MenuRibbonPosition { MenuRibbonPosition(rawValue: preferences.ribbonPositionID ?? "") ?? .top }
    var ribbonGlass: RibbonGlassPreferences { preferences.ribbonGlass ?? .standard }
    var canLoadMoreCatalogue: Bool { catalogueHasMore && !isSearchingCatalogue }
    var previewRequiresRefresh: Bool {
        if let value = previewSeries, let next = value.statisticalDescriptor,
           let previous = followedSeries.first(where: { $0.id == value.id })?.statisticalDescriptor {
            return !previous.usesSameMeasurement(as: next)
        }
        guard let descriptor = previewDescriptor,
              let previous = followedSeries.first(where: { $0.id == descriptor.key })?.descriptor else { return false }
        return !previous.usesSameMeasurement(as: descriptor)
    }

    func setPalette(_ palette: SemaPalette) { mutatePreferences { $0.themeID = palette.rawValue } }
    func setAppearance(_ appearance: SemaAppearance) {
        guard mutatePreferences({ $0.appearanceID = appearance.rawValue }) else { return }
        NSApplication.shared.appearance = appearance.nativeAppearance
    }
    func setRibbonPosition(_ position: MenuRibbonPosition) { mutatePreferences { $0.ribbonPositionID = position.rawValue } }
    func setRibbonGlass(_ glass: RibbonGlassPreferences) {
        guard glass != ribbonGlass else { return }
        mutatePreferences { $0.ribbonGlass = glass }
    }
    func isExchangeRateInverted(_ item: MarketSeries) -> Bool {
        guard let pair = item.exchangeRatePair else { return false }
        return (preferences.invertedCurrencyPairs ?? []).contains(pair.id)
    }
    func displayedSeries(_ item: MarketSeries) -> MarketSeries {
        guard isExchangeRateInverted(item) else { return item }
        if let cached = invertedExchangeRates[item.id], cached.source == item { return cached.display }
        guard let inverse = item.invertedExchangeRateForDisplay() else { return item }
        invertedExchangeRates[item.id] = (item, inverse)
        return inverse
    }
    func toggleExchangeRateDirection(_ item: MarketSeries) {
        guard let pair = item.exchangeRatePair, item.canInvertExchangeRate else { return }
        mutatePreferences { value in
            var inverted = value.invertedCurrencyPairs ?? []
            if inverted.contains(pair.id) { inverted.remove(pair.id) } else { inverted.insert(pair.id) }
            value.invertedCurrencyPairs = inverted
        }
    }
    var profile: LocalProfile { preferences.profile ?? LocalProfile() }
    @discardableResult func setProfile(_ profile: LocalProfile) -> Bool { mutatePreferences { $0.profile = profile } }
    func isSourceEnabled(_ id: String) -> Bool { preferences.isSourceEnabled(id) }
    func sourceID(for id: String) -> String { statisticalDescriptors[id]?.dataset.source.rawValue ?? "webstat" }
    func isSourceEnabled(for id: String) -> Bool { isSourceEnabled(sourceID(for: id)) }
    func sourceName(_ id: String) -> String { id == "webstat" ? "Webstat" : StatisticalSource(rawValue: id)?.title ?? id }
    func sourceSeriesCount(_ id: String) -> Int { storedFollowedSeries.filter { sourceID(for: $0.id) == id }.count }
    func setSourceEnabled(_ id: String, enabled: Bool) {
        guard id == "webstat" || StatisticalSource(rawValue: id) != nil, enabled != isSourceEnabled(id) else { return }
        guard mutatePreferences({ value in
            var disabled = value.disabledSourceIDs ?? []
            if enabled { disabled.remove(id) } else { disabled.insert(id) }
            value.disabledSourceIDs = disabled
            if !enabled {
                let rules = value.alerts.filter { $0.isEnabled && sourceID(for: $0.seriesID) == id }.map(\.id)
                value.alertBaselineIDs = (value.alertBaselineIDs ?? []).union(rules)
            }
        }) else { return }
        sourceGenerations[id] = UUID()
        if !enabled {
            if id == "webstat" { cancelCatalogueSearch() }
            if previewSourceID == id { closePreview() }
            if let historyLoadingID, sourceID(for: historyLoadingID) == id { cancelHistory() }
        }
    }
    func followedMatch(for value: MarketSeries) -> MarketSeries? {
        followedSeries.first { SeriesEquivalence.matches($0, value) }
    }
    func isFollowing(_ id: String) -> Bool { preferences.followedSeriesIDs.contains(WebstatClient.canonicalID(id)) }
    func isFavorite(_ id: String) -> Bool {
        guard let item = series.first(where: { $0.id == id }) else { return preferences.favoriteIDs.contains(id) }
        return storedFollowedSeries.contains { preferences.favoriteIDs.contains($0.id) && SeriesEquivalence.matches($0, item) }
    }
    func toggleFavorite(_ id: String) {
        guard isFollowing(id) else { return }
        let equivalentIDs = Set(storedFollowedSeries.filter { candidate in
            series.first(where: { $0.id == id }).map { SeriesEquivalence.matches($0, candidate) } ?? false
        }.map(\.id))
        let wasFavorite = isFavorite(id)
        mutatePreferences { value in
            if wasFavorite { value.favoriteIDs.subtract(equivalentIDs) } else { value.favoriteIDs.insert(id) }
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
        guard isSourceEnabled("webstat") else { return false }
        if isFollowing(descriptor.key) { return true }
        do {
            let value: MarketSeries
            if let previewSeries, previewSeries.id == descriptor.key { value = previewSeries }
            else { value = try await fetchRecent(descriptor: descriptor, apiKey: requiredKey()) }
            guard isSourceEnabled("webstat") else { return false }
            return try saveFollowed(value)
        } catch { previewError = error.localizedDescription; return false }
    }

    @discardableResult func followStatisticalPreview() -> Bool {
        guard let value = previewSeries, value.statisticalDescriptor != nil, !value.observations.isEmpty,
              !isLoadingPreview, previewError == nil else { return false }
        if isFollowing(value.id) { return true }
        do { return try saveFollowed(value) }
        catch { previewError = error.localizedDescription; return false }
    }
    @discardableResult func usePreviewSource() -> Bool {
        guard let value = previewSeries, !value.observations.isEmpty, !isLoadingPreview, previewError == nil,
              let previous = followedMatch(for: value), previous.id != value.id,
              isSourceEnabled(value.statisticalDescriptor?.dataset.source.rawValue ?? "webstat") else { return false }
        let ids = Set(storedFollowedSeries.filter { SeriesEquivalence.matches($0, value) }.map(\.id))
        do {
            try storage.cacheWebstat((series.filter { $0.id != value.id } + [value]).filter { !$0.isDemo })
            guard mutatePreferences({ next in
                var inserted = false
                next.followedSeriesIDs = next.followedSeriesIDs.compactMap { id in
                    guard ids.contains(id) else { return id }
                    if inserted { return nil }; inserted = true; return value.id
                }
                if !next.favoriteIDs.isDisjoint(with: ids) { next.favoriteIDs.subtract(ids); next.favoriteIDs.insert(value.id) }
                next.alerts = next.alerts.map { rule in
                    guard ids.contains(rule.seriesID) else { return rule }
                    return AlertRule(id: rule.id, seriesID: value.id, direction: rule.direction, threshold: rule.threshold,
                        isEnabled: rule.isEnabled, condition: rule.effectiveCondition,
                        lastEvaluatedAt: max(rule.lastEvaluatedAt ?? .distantPast, value.latest?.date ?? .distantPast))
                }
            }) else { return false }
            merge([value]); if ids.contains(selectedSeriesID) { selectedSeriesID = value.id }
            status = "Source du repère : \(value.originBadge). Favori et règles conservés."
            return true
        } catch { previewError = error.localizedDescription; return false }
    }
    private func saveFollowed(_ value: MarketSeries) throws -> Bool {
        let source = value.statisticalDescriptor?.dataset.source.rawValue ?? "webstat"
        guard isSourceEnabled(source) else { return false }
        if let existing = followedMatch(for: value) {
            status = "Ce repère est déjà suivi via \(existing.originBadge)."
            return true
        }
        // Persist the cache before preferences, for every provider.
        let merged = series.filter { $0.id != value.id } + [value]
        try storage.cacheWebstat(merged.filter { !$0.isDemo })
        guard mutatePreferences({ $0.followedSeriesIDs.append(value.id) }) else { return false }
        merge([value])
        hasLoadedWebstat = series.contains { !$0.isDemo && $0.sourceURL?.host == "webstat.banque-france.fr" }
        status = "Repère ajouté · \(value.source)."
        if selectedSeries == nil { show(value) }
        return true
    }

    @discardableResult func unfollow(_ id: String) -> Bool {
        let ids = Set(storedFollowedSeries.filter { candidate in
            series.first(where: { $0.id == id }).map { SeriesEquivalence.matches($0, candidate) } ?? false
        }.map(\.id)).union([id])
        let result = mutatePreferences { value in
            value.followedSeriesIDs.removeAll { ids.contains($0) }
            value.favoriteIDs.subtract(ids)
            for index in value.alerts.indices where ids.contains(value.alerts[index].seriesID) { value.alerts[index].isEnabled = false }
        }
        if result { reconcileSelection() }
        return result
    }

    func moveFollowed(_ id: String, by offset: Int) {
        var ordered = followedSeries
        guard let index = ordered.firstIndex(where: { $0.id == id }) else { return }
        let target = index + offset
        guard ordered.indices.contains(target) else { return }
        ordered.swapAt(index, target); reorderFollowed(ordered)
    }
    func moveFollowed(from offsets: IndexSet, to destination: Int) {
        var ordered = followedSeries
        guard offsets.allSatisfy({ ordered.indices.contains($0) }) else { return }
        let moved = offsets.sorted().map { ordered[$0] }
        for index in offsets.sorted(by: >) { ordered.remove(at: index) }
        let target = destination - offsets.filter { $0 < destination }.count
        ordered.insert(contentsOf: moved, at: min(max(0, target), ordered.count)); reorderFollowed(ordered)
    }
    private func reorderFollowed(_ ordered: [MarketSeries]) {
        let groups = ordered.flatMap { item in storedFollowedSeries.filter { SeriesEquivalence.matches(item, $0) }.map(\.id) }
        let unknown = preferences.followedSeriesIDs.filter { id in !groups.contains(id) }
        mutatePreferences { $0.followedSeriesIDs = groups + unknown }
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
        selectedSeriesID = followedMatch(for: item)?.id ?? item.id; category = item.category
        if !item.supports(period) { period = .all }
    }

    var shortcuts: ShortcutPreferences { preferences.shortcuts ?? .standard }

    func activateShortcuts() {
        do { try globalShortcuts.apply(shortcuts); shortcutError = nil }
        catch { shortcutError = error.localizedDescription }
    }

    func setShortcut(_ shortcut: AppShortcut?, for action: ShortcutAction) {
        var next = preferences
        var bindings = shortcuts; bindings[action] = shortcut; next.shortcuts = bindings
        do { try globalShortcuts.apply(bindings) }
        catch {
            let message = error.localizedDescription
            activateShortcuts()
            shortcutError = message
            return
        }
        if commit(next) { shortcutError = nil }
        else {
            activateShortcuts()
            shortcutError = errorMessage
        }
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
        for id in preferences.followedSeriesIDs {
            let source = sourceID(for: id)
            guard isSourceEnabled(source), generations[source] == sourceGenerations[source] else { continue }
            do {
                try Task.checkCancellation()
                let old = series.first { $0.id == id && !$0.isDemo }
                let value: MarketSeries
                var measurementChanged = false
                if let descriptor = old?.statisticalDescriptor ?? statisticalDescriptors[id] {
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
            catch { if isSourceEnabled(source), generations[source] == sourceGenerations[source] { failures[id] = error.localizedDescription } }
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
        webstatError = failures.keys.contains { id in series.first(where: { $0.id == id })?.statisticalDescriptor == nil }
            ? "Certaines séries Webstat demandent une vérification. Consultez leur détail." : nil
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
        guard hasWebstatKey, isSourceEnabled("webstat") else { isSearchingCatalogue = false; return }
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
        guard isSourceEnabled("webstat") else { return }
        previewSourceID = "webstat"
        statisticalPreviewRequest = nil
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
    func openStatisticalPreview(dataset: StatisticalDataset, structure: StatisticalStructure, key: String) {
        guard isSourceEnabled(dataset.source.rawValue) else { return }
        closePreview()
        previewSourceID = dataset.source.rawValue
        let requestID = UUID().uuidString; statisticalPreviewRequest = requestID; isLoadingPreview = true
        previewTask = Task {
            do {
                let value = try await StatisticalClient().fetch(dataset: dataset, structure: structure, key: key)
                try Task.checkCancellation()
                guard statisticalPreviewRequest == requestID else { return }
                if let old = series.first(where: { $0.id == value.id && !$0.isDemo }),
                   let previous = old.statisticalDescriptor, let next = value.statisticalDescriptor,
                   previous.usesSameMeasurement(as: next) {
                    previewSeries = value.replacing(observations: old.observations + value.observations, completeHistory: old.hasCompleteHistory)
                } else { previewSeries = value }
                if previewRequiresRefresh { previewError = "L’unité, l’échelle ou la base a changé. Actualisez vos repères et vérifiez les seuils avant de l’ouvrir." }
                isLoadingPreview = false
            } catch is CancellationError { }
            catch {
                guard statisticalPreviewRequest == requestID else { return }
                previewError = error.localizedDescription; isLoadingPreview = false
            }
        }
    }
    func closePreview() {
        previewTask?.cancel()
        previewSourceID = nil
        if historyLoadingID == previewDescriptor?.key || historyLoadingID == previewSeries?.id { cancelHistory() }
        previewDescriptor = nil; statisticalPreviewRequest = nil; previewSeries = nil; previewError = nil; isLoadingPreview = false
    }
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
        guard isSourceEnabled(for: item.id) else { return }
        if let descriptor = item.statisticalDescriptor {
            loadStatisticalHistory(item, descriptor: descriptor); return
        }
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

    private func loadStatisticalHistory(_ item: MarketSeries, descriptor: StatisticalSeriesDescriptor) {
        historyTask?.cancel(); let generation = UUID(); historyGeneration = generation
        historyLoadingID = item.id; historyProgress = "Chargement de l’historique publié…"
        historyTask = Task {
            defer { if historyGeneration == generation { historyLoadingID = nil; historyProgress = nil } }
            do {
                let value = try await StatisticalClient().fetch(descriptor, fullHistory: true)
                try Task.checkCancellation()
                guard historyGeneration == generation else { return }
                if isFollowing(item.id) {
                    try storage.cacheWebstat((series.filter { $0.id != item.id } + [value]).filter { !$0.isDemo })
                    merge([value])
                }
                if previewSeries?.id == item.id { previewSeries = value }
            } catch is CancellationError { }
            catch { seriesErrors[item.id] = error.localizedDescription; if previewSeries?.id == item.id { previewError = error.localizedDescription } }
        }
    }

    func addAlert(seriesID: String, direction: AlertDirection, threshold: Decimal) -> Bool {
        guard let item = macroSeries.first(where: { $0.id == seriesID }), item.canAlert, isSourceEnabled(for: seriesID) else { return false }
        let rule = AlertRule(seriesID: seriesID, direction: direction, threshold: threshold,
            condition: .level, lastEvaluatedAt: item.isDemo ? nil : item.latest?.date)
        guard rule.isValid, mutatePreferences({ $0.alerts.append(rule) }) else { return false }
        section = .alerts; return true
    }
    func toggleAlert(_ id: UUID) {
        guard let index = preferences.alerts.firstIndex(where: { $0.id == id }) else { return }
        let rule = preferences.alerts[index]
        let item = followedSeries.first { $0.id == rule.seriesID }
        guard isSourceEnabled(for: rule.seriesID), rule.isEnabled || (item?.canAlert == true) else { return }
        mutatePreferences { value in
            value.alerts[index].isEnabled.toggle()
            if value.alerts[index].isEnabled { value.alerts[index].lastEvaluatedAt = item?.isDemo == false ? item?.latest?.date : nil }
        }
    }
    func deleteAlert(_ id: UUID) { mutatePreferences { $0.alerts.removeAll { $0.id == id }; $0.alertBaselineIDs?.remove(id) } }
    func simulate(_ rule: AlertRule) {
        guard let item = series.first(where: { $0.id == rule.seriesID }), item.canAlert, isSourceEnabled(for: rule.seriesID) else { return }
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
                guard isSourceEnabled(for: rule.seriesID) else { return }
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
                  isSourceEnabled(for: rule.seriesID),
                  let item = values.first(where: { $0.id == rule.seriesID }), !item.isDemo, item.canAlert,
                  let latest = item.latest else { continue }
            if next.alertBaselineIDs?.contains(rule.id) == true {
                next.alerts[index].lastEvaluatedAt = max(latest.date, rule.lastEvaluatedAt ?? latest.date)
                next.alertBaselineIDs?.remove(rule.id); advanced = true
                continue
            }
            guard rule.lastEvaluatedAt.map({ latest.date > $0 }) ?? true else { continue }
            events += AlertEvaluator.newEvents(rule, series: item)
            next.alerts[index].lastEvaluatedAt = latest.date; advanced = true
        }
        guard advanced, commit(next) else { return }
        recentAlertEvents = Array((recentAlertEvents + events).suffix(20))
        guard preferences.notificationsEnabled, !events.isEmpty else { return }
        Task {
            for event in events {
                guard isSourceEnabled(for: event.seriesID) else { continue }
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
            if let descriptor = value.statisticalDescriptor { statisticalDescriptors[value.id] = descriptor }
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
