import Foundation
import Observation
import MarketCore

enum WorkspaceSection: String, CaseIterable, Identifiable {
    case overview, favorites, alerts
    var id: String { rawValue }
    var title: String {
        switch self { case .overview: "Panorama"; case .favorites: "Favoris"; case .alerts: "Alertes" }
    }
    var symbol: String {
        switch self { case .overview: "square.grid.2x2"; case .favorites: "star"; case .alerts: "bell" }
    }
}

@Observable @MainActor
final class AppStore {
    var series = DemoCatalog.series().filter { $0.category != .funds }
    var preferences = AppPreferences()
    var section: WorkspaceSection = .overview
    var category: SeriesCategory = .markets
    var selectedSeriesID = "eurusd"
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

    var macroSeries: [MarketSeries] { series.filter { $0.category != .funds } }
    var favorites: [MarketSeries] { series.filter { preferences.favoriteIDs.contains($0.id) } }
    var selectedSeries: MarketSeries { series.first { $0.id == selectedSeriesID } ?? series[0] }
    var originSummary: String { hasLoadedWebstat ? "Banque de France · Webstat" : "Webstat à connecter · démonstration disponible" }
    var macroAlerts: [AlertRule] {
        preferences.alerts.filter { rule in
            rule.effectiveCondition == .level && macroSeries.contains { $0.id == rule.seriesID }
        }
    }
    var palette: SemaPalette { SemaPalette(rawValue: preferences.themeID ?? "") ?? .teal }

    func setPalette(_ palette: SemaPalette) {
        preferences.themeID = palette.rawValue
        save()
    }

    func isFavorite(_ id: String) -> Bool { preferences.favoriteIDs.contains(id) }

    func toggleFavorite(_ id: String) {
        if preferences.favoriteIDs.contains(id) { preferences.favoriteIDs.remove(id) }
        else { preferences.favoriteIDs.insert(id) }
        save()
    }

    func show(_ item: MarketSeries) {
        guard item.category != .funds else { return }
        selectedSeriesID = item.id
        category = item.category
        if !item.supports(period) {
            period = HistoryPeriod.allCases.last(where: { item.supports($0) }) ?? .month
        }
    }

    func checkWebstatKey() async {
        guard !didCheckWebstatKey else { return }
        didCheckWebstatKey = true
        do { hasWebstatKey = try await webstatKeychain.read() != nil }
        catch { webstatError = error.localizedDescription }
    }

    func connectWebstat(apiKey: String) async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        webstatError = nil
        defer { isLoading = false }
        do {
            let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let values = try await WebstatClient().fetch(apiKey: key)
            try await webstatKeychain.save(key)
            hasWebstatKey = true
            applyWebstat(values)
            return true
        } catch {
            webstatError = "Connexion impossible : \(error.localizedDescription) Les données affichées sont conservées."
            return false
        }
    }

    func refreshWebstat() async {
        guard !isLoading else { return }
        isLoading = true
        webstatError = nil
        defer { isLoading = false }
        do {
            guard let key = try await webstatKeychain.read() else {
                hasWebstatKey = false
                throw WebstatClient.ClientError.missingKey
            }
            applyWebstat(try await WebstatClient().fetch(apiKey: key))
        } catch {
            webstatError = "Actualisation impossible : \(error.localizedDescription) Les données affichées sont conservées."
            status = webstatError
        }
    }

    func removeWebstatKey() async {
        guard !isLoading else { return }
        isLoading = true
        webstatError = nil
        defer { isLoading = false }
        do {
            try await webstatKeychain.remove()
            hasWebstatKey = false
            status = "Clé Webstat retirée · les dernières données restent consultables dans le cache local."
        } catch { webstatError = error.localizedDescription }
    }

    private func applyWebstat(_ values: [MarketSeries]) {
        merge(values)
        hasLoadedWebstat = true
        webstatError = nil
        status = "\(values.count) repères Webstat actualisés · alertes vérifiées sur les nouvelles observations."
        do { try storage.cacheWebstat(values) }
        catch { errorMessage = "Les repères sont chargés, mais leur sauvegarde locale a échoué." }
        evaluateAlerts(in: values)
    }

    func restoreDemo() {
        series = DemoCatalog.series().filter { $0.category != .funds }
        if !series.contains(where: { $0.id == selectedSeriesID }) { selectedSeriesID = "eurusd" }
        hasLoadedWebstat = false
        status = "Données de démonstration · aucun cours actuel."
    }

    func addAlert(seriesID: String, direction: AlertDirection, threshold: Decimal) -> Bool {
        guard let item = macroSeries.first(where: { $0.id == seriesID }) else { return false }
        let rule = AlertRule(seriesID: seriesID, direction: direction, threshold: threshold,
                             condition: .level, lastEvaluatedAt: item.isDemo ? nil : item.latest?.date)
        guard rule.isValid else { return false }
        preferences.alerts.append(rule)
        save()
        section = .alerts
        return true
    }

    func toggleAlert(_ id: UUID) {
        guard let index = preferences.alerts.firstIndex(where: { $0.id == id }) else { return }
        preferences.alerts[index].isEnabled.toggle()
        if preferences.alerts[index].isEnabled {
            let item = macroSeries.first { $0.id == preferences.alerts[index].seriesID }
            preferences.alerts[index].lastEvaluatedAt = item?.isDemo == false ? item?.latest?.date : nil
        }
        save()
    }

    func deleteAlert(_ id: UUID) {
        preferences.alerts.removeAll { $0.id == id }
        save()
    }

    func simulate(_ rule: AlertRule) {
        guard let item = macroSeries.first(where: { $0.id == rule.seriesID }) else { return }
        let step = Decimal(string: "0.1")!
        let sign: Decimal = rule.direction == .fall ? -1 : 1
        let sample = MarketSeries(
            id: item.id, name: item.name, subtitle: item.subtitle, category: item.category, unit: item.unit,
            source: "Simulation explicite", isDemo: true,
            observations: [MarketObservation(date: Date().addingTimeInterval(-86_400), value: rule.threshold - sign * step),
                           MarketObservation(date: Date(), value: rule.threshold + sign * step)]
        )
        // Testing is deliberate and remains available even if the rule is paused.
        let activeRule = AlertRule(id: rule.id, seriesID: rule.seriesID, direction: rule.direction,
                                   threshold: rule.threshold, condition: .level)
        simulatedEvent = AlertEvaluator.evaluate(activeRule, series: sample)
        if preferences.notificationsEnabled {
            Task {
                do {
                    try await notifications.send(title: item.name,
                        body: "Seuil de \(MarketFormat.number(rule.threshold, digits: item.fractionDigits)) \(item.unit.symbol) franchi dans la démonstration.", isDemo: true)
                } catch { errorMessage = "La notification système n’a pas pu être envoyée : \(error.localizedDescription)" }
            }
        }
    }

    private func evaluateAlerts(in values: [MarketSeries]) {
        var events: [AlertEvent] = []
        var didAdvance = false
        for index in preferences.alerts.indices {
            let rule = preferences.alerts[index]
            guard rule.isEnabled, rule.effectiveCondition == .level,
                  let item = values.first(where: { $0.id == rule.seriesID }), !item.isDemo,
                  let latest = item.latest,
                  rule.lastEvaluatedAt.map({ latest.date > $0 }) ?? true else { continue }
            events += AlertEvaluator.newEvents(rule, series: item)
            preferences.alerts[index].lastEvaluatedAt = latest.date
            didAdvance = true
        }
        guard didAdvance, save() else { return }
        recentAlertEvents = Array((recentAlertEvents + events).suffix(20))
        guard preferences.notificationsEnabled, !events.isEmpty else { return }
        Task {
            for event in events {
                guard let item = values.first(where: { $0.id == event.seriesID }), let value = event.observedValue else { continue }
                do {
                    try await notifications.send(title: item.name,
                        body: "Seuil franchi : \(MarketFormat.number(value, digits: item.fractionDigits)) \(item.unit.symbol) · observation du \(MarketFormat.date(event.observedAt)).", isDemo: false)
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
            guard value.category != .funds else { continue }
            if let index = series.firstIndex(where: { $0.id == value.id }) { series[index] = value }
            else { series.append(value) }
        }
    }

    @discardableResult private func save() -> Bool {
        guard canSavePreferences else {
            errorMessage = "La sauvegarde est désactivée pour préserver le fichier de réglages illisible."
            return false
        }
        do { try storage.preferences.save(preferences); return true }
        catch { errorMessage = "Les modifications n’ont pas été sauvegardées : \(error.localizedDescription)"; return false }
    }
}
