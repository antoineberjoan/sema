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
        let step: Decimal = 0.1
        let sign: Decimal = rule.direction == .fall ? -1 : 1
        let sample = item.replacing(observations: [
            .init(date: now.addingTimeInterval(-60), value: rule.threshold - sign * step),
            .init(date: now, value: rule.threshold + sign * step)
        ])
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
        var events: [AlertEvent] = []; var next = preferences; var hasAdvanced = false
        for index in next.alerts.indices {
            let rule = next.alerts[index]
            guard rule.isEnabled, rule.effectiveCondition != .relativeChange,
                  isSourceEnabled(for: rule.seriesID),
                  let item = values.first(where: { $0.id == rule.seriesID }), item.canAlert,
                  let latest = item.latest else { continue }
            if next.alertBaselineIDs?.contains(rule.id) == true {
                next.alerts[index].lastEvaluatedAt = max(latest.date, rule.lastEvaluatedAt ?? latest.date)
                next.alertBaselineIDs?.remove(rule.id); hasAdvanced = true
                continue
            }
            guard rule.lastEvaluatedAt.map({ latest.date > $0 }) ?? true else { continue }
            events += AlertEvaluator.newEvents(rule, series: item, sensitivity: moveSensitivity)
            next.alerts[index].lastEvaluatedAt = latest.date; hasAdvanced = true
        }
        guard hasAdvanced, commit(next) else { return }
        recentAlertEvents = Array((recentAlertEvents + events).suffix(Self.recentAlertLimit))
        guard preferences.canNotify, !events.isEmpty else { return }
        let entries = events.compactMap { event -> (name: String, line: String)? in
            guard isSourceEnabled(for: event.seriesID), let item = values.first(where: { $0.id == event.seriesID }) else { return nil }
            return (MarketFormat.name(item), Self.notificationLine(for: event, series: item))
        }
        guard let first = entries.first else { return }
        let lines = entries.map(\.line)
        let moves = events.filter { $0.ratio != nil }.count
        let title = entries.count == 1 ? first.name : "\(entries.count) repères"
        let subtitle = moves == events.count ? "Mouvement inhabituel" : moves == 0 ? "Seuil franchi" : "Alertes"
        let target: NotificationTarget = entries.count == 1 ? .series(events[0].seriesID) : .section(.alerts)
        Task {
            do { try await notifications.send(title: title, subtitle: subtitle, body: lines.joined(separator: "\n"), target: target) }
            catch { errorMessage = "La notification système n’a pas pu être envoyée : \(error.localizedDescription)" }
        }
    }

    /// Une ligne par événement, regroupées dans une seule notification : « S&P 500 · −4,40 % · 4,0× l’habituel ».
    private static func notificationLine(for event: AlertEvent, series: MarketSeries) -> String {
        let name = MarketFormat.name(series)
        if let ratio = event.ratio {
            return "\(name) · \(MarketFormat.sessionChange(event.changePercent, series: series)) · \(MarketFormat.ratio(ratio)) l’habituel"
        }
        let value = event.observedValue.map { MarketFormat.number($0, digits: series.fractionDigits) } ?? "—"
        return "\(name) · seuil franchi : \(value) \(MarketFormat.unit(series)) · \(MarketFormat.date(event.observedAt))"
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
