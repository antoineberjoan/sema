import Foundation
import Observation
import MarketCore

enum WorkspaceSection: String, CaseIterable, Identifiable {
    case overview, favorites, funds, alerts
    var id: String { rawValue }
    var title: String {
        switch self { case .overview: "Panorama"; case .favorites: "Favoris"; case .funds: "Fonds suivis"; case .alerts: "Alertes" }
    }
    var symbol: String {
        switch self { case .overview: "square.grid.2x2"; case .favorites: "star"; case .funds: "bookmark"; case .alerts: "bell" }
    }
}

@Observable @MainActor
final class AppStore {
    var series = DemoCatalog.series()
    var preferences = AppPreferences()
    var section: WorkspaceSection = .overview
    var category: SeriesCategory = .markets
    var selectedSeriesID = "eurusd"
    var selectedFundID = "atlas-i-eur"
    var period: HistoryPeriod = .month
    var search = ""
    var isLoading = false
    var hasLoadedWebstat = false
    var hasWebstatKey = false
    var status: String?
    var errorMessage: String?
    var simulatedEvent: AlertEvent?
    var isAlertSheetPresented = false
    private let storage: LocalStorage
    private let notifications = NotificationService()
    private let webstatKeychain = WebstatKeychain()
    private var didCheckWebstatKey = false
    private var canSavePreferences = true

    init(storage: LocalStorage = .applicationDefault()) {
        self.storage = storage
        do {
            preferences = try storage.preferences.load()
        } catch {
            // Preserve unreadable files rather than silently replacing user choices.
            canSavePreferences = false
            errorMessage = "Les réglages n’ont pas pu être lus. Le fichier existant est conservé : \(error.localizedDescription)"
        }
        do {
            let cached = try storage.cachedWebstat()
            if !cached.isEmpty {
                merge(cached)
                hasLoadedWebstat = true
                status = "Repères Webstat conservés localement · consultez la période et la date de publication."
            } else {
                let previousRates = try storage.cachedRates()
                if !previousRates.isEmpty {
                    merge(previousRates)
                    status = "Ancien cache BCE · connectez Webstat dans les réglages pour actualiser les repères."
                }
            }
        } catch {
            errorMessage = "Le cache des données est illisible. Une actualisation peut le remplacer."
        }
    }

    var funds: [MarketSeries] { series.filter { $0.category == .funds } }
    var macroSeries: [MarketSeries] { series.filter { $0.category != .funds } }
    var favorites: [MarketSeries] { series.filter { preferences.favoriteIDs.contains($0.id) } }
    var selectedSeries: MarketSeries { series.first { $0.id == selectedSeriesID } ?? series[0] }
    var selectedFund: MarketSeries { funds.first { $0.id == selectedFundID } ?? funds[0] }
    var originSummary: String { hasLoadedWebstat ? "Webstat · fonds en démonstration" : "Webstat à connecter · démonstration disponible" }

    func isFavorite(_ id: String) -> Bool { preferences.favoriteIDs.contains(id) }

    func toggleFavorite(_ id: String) {
        if preferences.favoriteIDs.contains(id) { preferences.favoriteIDs.remove(id) }
        else { preferences.favoriteIDs.insert(id) }
        save()
    }

    func show(_ item: MarketSeries) {
        if item.category == .funds { selectedFundID = item.id; section = .funds }
        else { selectedSeriesID = item.id; category = item.category }
        if !item.hasAnnualHistory && period == .year { period = .quarter }
    }

    func checkWebstatKey() async {
        guard !didCheckWebstatKey else { return }
        didCheckWebstatKey = true
        do { hasWebstatKey = try await webstatKeychain.read() != nil }
        catch { errorMessage = error.localizedDescription }
    }

    func connectWebstat(apiKey: String) async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        defer { isLoading = false }
        do {
            let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let values = try await WebstatClient().fetch(apiKey: key)
            try await webstatKeychain.save(key)
            hasWebstatKey = true
            applyWebstat(values)
            return true
        } catch {
            errorMessage = "Connexion impossible : \(error.localizedDescription) Les données affichées sont conservées."
            return false
        }
    }

    func refreshWebstat() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            guard let key = try await webstatKeychain.read() else {
                hasWebstatKey = false
                throw WebstatClient.ClientError.missingKey
            }
            applyWebstat(try await WebstatClient().fetch(apiKey: key))
        } catch {
            errorMessage = "Actualisation impossible : \(error.localizedDescription) Les données affichées sont conservées."
        }
    }

    func removeWebstatKey() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await webstatKeychain.remove()
            hasWebstatKey = false
            status = "Clé Webstat retirée · les dernières données restent consultables dans le cache local."
        } catch { errorMessage = error.localizedDescription }
    }

    private func applyWebstat(_ values: [MarketSeries]) {
        merge(values)
        hasLoadedWebstat = true
        errorMessage = nil
        status = "\(values.count) repères Webstat actualisés · les fonds et les alertes restent en démonstration."
        do { try storage.cacheWebstat(values) }
        catch { errorMessage = "Les repères sont chargés, mais leur sauvegarde locale a échoué." }
    }

    func restoreDemo() {
        series = DemoCatalog.series()
        hasLoadedWebstat = false
        status = "Données de démonstration · aucun cours actuel."
    }

    func addAlert(seriesID: String, direction: AlertDirection, threshold: Decimal) -> Bool {
        let rule = AlertRule(seriesID: seriesID, direction: direction, threshold: threshold)
        guard rule.isValid, funds.contains(where: { $0.id == seriesID }) else { return false }
        preferences.alerts.append(rule)
        save()
        section = .alerts
        return true
    }

    func toggleAlert(_ id: UUID) {
        guard let index = preferences.alerts.firstIndex(where: { $0.id == id }) else { return }
        preferences.alerts[index].isEnabled.toggle()
        save()
    }

    func deleteAlert(_ id: UUID) {
        preferences.alerts.removeAll { $0.id == id }
        save()
    }

    func simulate(_ rule: AlertRule) {
        guard let fund = funds.first(where: { $0.id == rule.seriesID }) else { return }
        let change = (rule.threshold + Decimal(string: "0.4")!) * (rule.direction == .fall ? -1 : 1)
        let reference: Decimal = 100
        let sample = MarketSeries(
            id: fund.id, name: fund.name, subtitle: fund.subtitle, category: .funds, unit: .eur,
            source: "Simulation explicite", isDemo: true,
            observations: [MarketObservation(date: Date().addingTimeInterval(-86_400), value: reference),
                           MarketObservation(date: Date(), value: reference * (1 + change / 100))]
        )
        // Testing is deliberate and remains available even if the rule is paused.
        let activeRule = AlertRule(id: rule.id, seriesID: rule.seriesID, direction: rule.direction, threshold: rule.threshold)
        simulatedEvent = AlertEvaluator.evaluate(activeRule, series: sample)
        if preferences.notificationsEnabled {
            Task {
                do {
                    try await notifications.sendDemo(title: fund.name,
                        body: "Seuil de \(MarketFormat.number(rule.threshold, digits: 1)) % franchi dans la démonstration.")
                } catch { errorMessage = "La notification système n’a pas pu être envoyée : \(error.localizedDescription)" }
            }
        }
    }

    func setNotificationsEnabled(_ enabled: Bool) async {
        if enabled {
            do {
                preferences.notificationsEnabled = try await notifications.requestPermission()
                if !preferences.notificationsEnabled { errorMessage = "Les notifications ne sont pas autorisées dans les Réglages Système." }
            } catch { errorMessage = error.localizedDescription }
        } else { preferences.notificationsEnabled = false }
        save()
    }

    private func merge(_ values: [MarketSeries]) {
        for value in values {
            if let index = series.firstIndex(where: { $0.id == value.id }) { series[index] = value }
            else { series.insert(value, at: series.firstIndex { $0.category == .funds } ?? series.endIndex) }
        }
    }

    private func save() {
        guard canSavePreferences else {
            errorMessage = "La sauvegarde est désactivée pour préserver le fichier de réglages illisible."
            return
        }
        do { try storage.preferences.save(preferences) }
        catch { errorMessage = "Les modifications n’ont pas été sauvegardées : \(error.localizedDescription)" }
    }
}
