// Coordonne les données, préférences et actions partagées par la fenêtre et le bandeau sur le MainActor.
import AppKit
import Foundation
import Observation
import MarketCore

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
    var opensAlertAfterSearch = false
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
    var previewSourceID: String?
    var statisticalCatalogues: [String: [StatisticalDataset]] = [:]
    var statisticalDescriptors: [String: StatisticalSeriesDescriptor] = [:]
    let storage: LocalStorage
    let notifications = NotificationService()
    let webstatKeychain = WebstatKeychain()
    var didCheckWebstatKey = false
    private var canSavePreferences = true
    var searchTask: Task<Void, Never>?
    var searchGeneration = UUID()
    var summaryExportSearch: WebstatSearch?
    var summaryExport: [WebstatSeriesDescriptor] = []
    var previewTask: Task<Void, Never>?
    var historyTask: Task<Void, Never>?
    var historyGeneration = UUID()
    var sourceGenerations: [String: UUID] = [:]
    @ObservationIgnored var invertedExchangeRates: [String: (source: MarketSeries, display: MarketSeries)] = [:]

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
    var storedFollowedSeries: [MarketSeries] { preferences.followedSeriesIDs.compactMap { id in series.first { $0.id == id } } }
    var followedSeries: [MarketSeries] { SeriesEquivalence.unique(storedFollowedSeries) }
    var macroSeries: [MarketSeries] { followedSeries }
    var alertableSeries: [MarketSeries] { followedSeries.filter { $0.canAlert && isSourceEnabled(for: $0.id) } }
    var favorites: [MarketSeries] { followedSeries.filter { isFavorite($0.id) } }
    var selectedSeries: MarketSeries? { followedSeries.first { $0.id == selectedSeriesID } ?? followedSeries.first }
    var originSummary: String {
        let sources = Set(followedSeries.filter { !$0.isDemo }.map(\.originBadge)).sorted()
        return sources.isEmpty ? "Démonstration · sources à explorer" : sources.joined(separator: " · ")
    }
    var canRefresh: Bool {
        preferences.followedSeriesIDs.contains { isSourceEnabled(for: $0) && (hasWebstatKey || statisticalDescriptors[$0] != nil) }
    }

    var profile: LocalProfile { preferences.profile ?? LocalProfile() }
    @discardableResult func setProfile(_ profile: LocalProfile) -> Bool { mutatePreferences { $0.profile = profile } }

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

    func show(_ item: MarketSeries) {
        if let historyLoadingID, historyLoadingID != item.id { cancelHistory() }
        selectedSeriesID = followedMatch(for: item)?.id ?? item.id; category = item.category
        if !item.supports(period) { period = .all }
    }

    func reconcileSelection() {
        if !followedSeries.contains(where: { $0.id == selectedSeriesID }) { selectedSeriesID = followedSeries.first?.id ?? "" }
    }

    func merge(_ values: [MarketSeries]) {
        for value in values where value.category != .funds {
            if let descriptor = value.statisticalDescriptor { statisticalDescriptors[value.id] = descriptor }
            if let index = series.firstIndex(where: { $0.id == value.id }) { series[index] = value } else { series.append(value) }
        }
    }
    @discardableResult func mutatePreferences(_ change: (inout AppPreferences) -> Void) -> Bool {
        var next = preferences; change(&next); return commit(next)
    }
    @discardableResult func commit(_ next: AppPreferences) -> Bool {
        guard canSavePreferences else { errorMessage = "La sauvegarde est désactivée pour préserver le fichier de réglages illisible."; return false }
        do { try storage.preferences.save(next); preferences = next; return true }
        catch { errorMessage = "Les modifications n’ont pas été sauvegardées : \(error.localizedDescription)"; return false }
    }
}
