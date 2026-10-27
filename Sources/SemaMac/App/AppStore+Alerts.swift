// Crée, suspend, supprime et évalue les règles de seuil, et pilote les notifications.
import Foundation
import MarketCore

extension AppStore {
    static let recentAlertLimit = 20
    var macroAlerts: [AlertRule] { preferences.alerts.filter { $0.effectiveCondition == .level } }

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



    func evaluateAlerts(in values: [MarketSeries]) {
        var events: [AlertEvent] = []; var next = preferences; var advanced = false
        for index in next.alerts.indices {
            let rule = next.alerts[index]
            guard rule.isEnabled, rule.effectiveCondition == .level,
                  isSourceEnabled(for: rule.seriesID),
                  let item = values.first(where: { $0.id == rule.seriesID }), item.canAlert,
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
        recentAlertEvents = Array((recentAlertEvents + events).suffix(Self.recentAlertLimit))
        guard preferences.notificationsEnabled, !events.isEmpty else { return }
        Task {
            for event in events {
                guard isSourceEnabled(for: event.seriesID) else { continue }
                guard let item = values.first(where: { $0.id == event.seriesID }), let value = event.observedValue else { continue }
                do { try await notifications.send(title: item.name,
                    body: "Seuil franchi : \(MarketFormat.number(value, digits: item.fractionDigits)) \(item.displayUnit) · observation du \(MarketFormat.date(event.observedAt)).") }
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
}
