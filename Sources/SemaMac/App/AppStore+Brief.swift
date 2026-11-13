// Compose le brief du matin à partir des repères suivis et l’envoie une fois par jour à l’heure choisie, ou au réveil du Mac.
import Foundation
import MarketCore

extension AppStore {
    /// Communiqués des banques centrales du dernier jour, montrés avec le brief.
    private static let briefPressWindow: TimeInterval = .day

    var brief: BriefPreferences { preferences.brief ?? BriefPreferences() }

    func setBrief(_ change: (inout BriefPreferences) -> Void) {
        var value = brief; change(&value)
        let schedule = value.isEnabled != brief.isEnabled || value.hour != brief.hour
            || value.minute != brief.minute || value.isWeekdaysOnly != brief.isWeekdaysOnly
        if mutatePreferences({ $0.brief = value }), schedule { rescheduleRefresh() }
    }

    /// Activer le brief demande les notifications, comme pour la première alerte.
    func setBriefEnabled(_ enabled: Bool) async {
        if enabled, !preferences.canNotify { await setNotificationsEnabled(true) }
        setBrief { $0.isEnabled = enabled && preferences.canNotify }
    }

    /// Brief du jour à partir des données locales ; l’agenda et les communiqués se chargent quand leurs sources sont actives.
    func morningBrief(now: Date = .now) async -> MorningBrief {
        var value = MorningBrief(series: alertableSeries, alerts: preferences.alerts, sensitivity: moveSensitivity, now: now)
        value.agenda = await economicReleases(on: now) ?? []
        value.pressReleases = await pressReleases(from: now.addingTimeInterval(-Self.briefPressWindow), to: now) ?? []
        return value
    }

    func sendBriefIfDue(now: Date = .now) async {
        guard preferences.canNotify, brief.isDue(now: now) else { return }
        // Noté en premier : un envoi raté n’est pas retenté chaque minute.
        setBrief { $0.lastSentAt = now }
        let value = await morningBrief(now: now)
        do { try await notifications.send(title: "Brief du matin", subtitle: MarketFormat.date(now), body: Self.briefLines(value).joined(separator: "\n"), target: .section(.brief)) }
        catch { errorMessage = "Le brief n’a pas pu être envoyé : \(error.localizedDescription)" }
    }

    /// Secondes avant le prochain brief, pour que le minuteur d’actualisation se réveille à temps.
    func nextBriefDelay(now: Date = .now) -> TimeInterval? {
        guard preferences.canNotify else { return nil }
        return brief.next(after: now).map { $0.timeIntervalSince(now) }
    }

    static func briefLines(_ brief: MorningBrief) -> [String] {
        var lines = brief.moves.map { move in
            "\(MarketFormat.name(move.series)) · \(MarketFormat.sessionChange(move.change, series: move.series))"
                + (move.ratio.map { " · \(MarketFormat.ratio($0)) l’habituel" } ?? "")
        }
        lines += brief.nearThresholds.map { near in "\(MarketFormat.name(near.series)) · \(nearText(near))" }
        if brief.isQuiet { lines.append("Aucun mouvement inhabituel ni seuil proche sur la dernière séance.") }
        if !brief.agenda.isEmpty { lines.append("Agenda : " + brief.agenda.prefix(3).map(\.name).joined(separator: ", ")) }
        if let release = brief.pressReleases.first { lines.append("\(release.feed.title) : \(release.title)") }
        return lines
    }

    static func nearText(_ near: MorningBrief.NearThreshold) -> String {
        let gap = near.series.unit == .percent ? MarketFormat.number(near.gap, digits: 2) + " pt" : MarketFormat.number(near.gap, digits: 1) + " %"
        let threshold = MarketFormat.number(near.rule.threshold, digits: near.series.fractionDigits) + " " + MarketFormat.unit(near.series)
        return "à \(gap) du seuil de \(threshold)"
    }
}
