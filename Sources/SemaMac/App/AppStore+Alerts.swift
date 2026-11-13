// Crée, suspend, supprime et évalue les seuils et la surveillance des mouvements, et regroupe les notifications.
import Foundation
import MarketCore

extension AppStore {
    static let recentAlertLimit = 20
    var macroAlerts: [AlertRule] { preferences.alerts.filter { $0.effectiveCondition == .level } }
    var moveWatches: [AlertRule] { preferences.alerts.filter { $0.effectiveCondition == .unusualMove } }
    var moveSensitivity: MoveSensitivity { MoveSensitivity(rawValue: preferences.moveSensitivityID ?? "") ?? .standard }
    func setMoveSensitivity(_ sensitivity: MoveSensitivity) { mutatePreferences { $0.moveSensitivityID = sensitivity.rawValue } }

    func isWatched(_ seriesID: String) -> Bool { moveWatches.contains { $0.seriesID == seriesID && $0.isEnabled } }
    func canWatch(_ item: MarketSeries) -> Bool { isFollowing(item.id) && item.canAlert && isSourceEnabled(for: item.id) }

    /// Un clic : lance ou arrête la surveillance des mouvements inhabituels. La première surveillance demande à macOS les notifications,
    /// ce qui vaut activation explicite, comme l’exige le contrat.
    func toggleWatch(_ item: MarketSeries) async {
        if moveWatches.contains(where: { $0.seriesID == item.id }) {
            mutatePreferences { $0.alerts.removeAll { $0.seriesID == item.id && $0.effectiveCondition == .unusualMove } }
            return
        }
        await watch([item])
    }

    /// Surveille en un clic chaque favori qui peut l’être.
    func watchFavorites() async { await watch(favorites.filter { canWatch($0) && !isWatched($0.id) }) }

    private func watch(_ items: [MarketSeries]) async {
        let watchable = items.filter(canWatch)
        guard !watchable.isEmpty else { return }
        if !preferences.canNotify { await setNotificationsEnabled(true) }
        mutatePreferences { value in
            value.alerts.removeAll { rule in rule.effectiveCondition == .unusualMove && watchable.contains { $0.id == rule.seriesID } }
            value.alerts += watchable.map { AlertRule.unusualMove(seriesID: $0.id, lastEvaluatedAt: $0.latest?.date) }
        }
    }

    func addAlert(seriesID: String, direction: AlertDirection, threshold: Decimal) -> Bool {
        guard let item = macroSeries.first(where: { $0.id == seriesID }), item.canAlert, isSourceEnabled(for: seriesID) else { return false }
        let rule = AlertRule(seriesID: seriesID, direction: direction, threshold: threshold,
            condition: .level, lastEvaluatedAt: item.latest?.date)
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
            if value.alerts[index].isEnabled { value.alerts[index].lastEvaluatedAt = item?.latest?.date }
        }
    }

    func deleteAlert(_ id: UUID) { mutatePreferences { $0.alerts.removeAll { $0.id == id }; $0.alertBaselineIDs?.remove(id) } }

    func simulate(_ rule: AlertRule) {
        guard preferences.canNotify,
              let item = series.first(where: { $0.id == rule.seriesID }), item.canAlert,
              isSourceEnabled(for: rule.seriesID) else { return }
        let now = Date()
        let sample = AlertEvaluator.testSample(for: rule, series: item, now: now)
        let testRule = AlertRule(id: rule.id, seriesID: rule.seriesID, direction: rule.direction,
                                 threshold: rule.threshold, condition: .level)
        guard let event = AlertEvaluator.evaluate(testRule, series: sample) else { return }
        Task {
            guard isSourceEnabled(for: rule.seriesID) else { return }
            do {
                try await notifications.send(title: MarketFormat.name(item), subtitle: "Test de notification",
                    body: "Seuil de \(MarketFormat.number(rule.threshold, digits: item.fractionDigits)) \(item.displayUnit) franchi · observation du \(MarketFormat.date(event.observedAt)).")
            } catch { errorMessage = "La notification système n’a pas pu être envoyée : \(error.localizedDescription)" }
        }
    }

    func evaluateAlerts(in values: [MarketSeries]) {
        let check = AlertEvaluator.check(rules: preferences.alerts, baselineIDs: preferences.alertBaselineIDs, series: values,
                                         sensitivity: moveSensitivity, isSourceEnabled: isSourceEnabled(for:))
        var next = preferences
        next.alerts = check.rules; next.alertBaselineIDs = check.baselineIDs
        let events = check.events
        guard check.hasAdvanced, commit(next) else { return }
        recentAlertEvents = Array((recentAlertEvents + events).suffix(Self.recentAlertLimit))
        guard preferences.canNotify, !events.isEmpty else { return }
        guard let summary = NotificationText.summary(events: events, series: values, isSourceEnabled: isSourceEnabled(for:)) else { return }
        Task {
            do { try await notifications.send(title: summary.title, subtitle: summary.subtitle, body: summary.body, target: summary.target) }
            catch { errorMessage = "La notification système n’a pas pu être envoyée : \(error.localizedDescription)" }
        }
    }

    func setNotificationsEnabled(_ enabled: Bool) async {
        var next = preferences
        if enabled {
            do {
                next.canNotify = try await notifications.requestPermission()
                if !next.canNotify { errorMessage = "Les notifications ne sont pas autorisées dans les Réglages Système." }
            } catch { errorMessage = error.localizedDescription }
        } else { next.canNotify = false }
        commit(next)
    }
}
