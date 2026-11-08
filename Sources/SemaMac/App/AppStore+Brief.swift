// Compose le brief du matin à partir des repères suivis et l’envoie une fois par jour à l’heure choisie, ou au réveil du Mac.
import Foundation
import MarketCore

extension AppStore {
    /// Central bank releases of the last day, shown with the brief.
    private static let briefPressWindow: TimeInterval = .day

    var brief: BriefPreferences { preferences.brief ?? BriefPreferences() }

    func setBrief(_ change: (inout BriefPreferences) -> Void) {
        var value = brief; change(&value)
        let schedule = value.isEnabled != brief.isEnabled || value.hour != brief.hour
            || value.minute != brief.minute || value.weekdaysOnly != brief.weekdaysOnly
        if mutatePreferences({ $0.brief = value }), schedule { rescheduleRefresh() }
    }

    /// Turning the brief on asks for notifications, the same way as the first alert.
    func setBriefEnabled(_ enabled: Bool) async {
        if enabled, !preferences.notificationsEnabled { await setNotificationsEnabled(true) }
        setBrief { $0.isEnabled = enabled && preferences.notificationsEnabled }
    }

    /// Brief of today from local data; the agenda and the releases are loaded when their sources are on.
    func morningBrief(now: Date = .now) async -> MorningBrief {
        var value = MorningBrief(series: alertableSeries, alerts: preferences.alerts, sensitivity: moveSensitivity, now: now)
        value.agenda = await economicReleases(on: now) ?? []
        value.pressReleases = await pressReleases(from: now.addingTimeInterval(-Self.briefPressWindow), to: now) ?? []
        return value
    }

    func sendBriefIfDue(now: Date = .now) async {
        guard preferences.notificationsEnabled, brief.isDue(now: now) else { return }
        // Recorded first: a failed delivery is not retried every minute.
        setBrief { $0.lastSentAt = now }
        let value = await morningBrief(now: now)
        do { try await notifications.send(title: "Brief du matin", subtitle: MarketFormat.date(now), body: Self.briefLines(value).joined(separator: "\n")) }
        catch { errorMessage = "Le brief n’a pas pu être envoyé : \(error.localizedDescription)" }
    }

    /// Seconds until the next brief, so the refresh timer wakes in time.
    func nextBriefDelay(now: Date = .now) -> TimeInterval? {
        guard preferences.notificationsEnabled else { return nil }
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
