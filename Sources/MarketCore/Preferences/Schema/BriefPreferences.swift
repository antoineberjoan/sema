// Réglages du brief du matin : activation, heure locale, jours ouvrés et dernier envoi, pour l’envoyer une fois par jour.
import Foundation

public struct BriefPreferences: Codable, Equatable, Sendable {
    public static let defaultHour = 8
    public static let defaultMinute = 0
    /// Jours examinés pour trouver le prochain jour permis ; une semaine en contient toujours un.
    private static let searchDays = 8

    public var isEnabled = false
    public var hour = BriefPreferences.defaultHour
    public var minute = BriefPreferences.defaultMinute
    public var isWeekdaysOnly = true
    public var lastSentAt: Date?

    enum CodingKeys: String, CodingKey {
        case isEnabled, hour, minute, lastSentAt
        case isWeekdaysOnly = "weekdaysOnly"
    }

    public init() {}

    /// Heure du brief au jour du calendrier de `date`, ou nil un week-end quand seuls les jours ouvrés sont choisis.
    public func time(on date: Date, calendar: Calendar = .current) -> Date? {
        if isWeekdaysOnly, calendar.isDateInWeekend(date) { return nil }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
    }

    /// Dû une fois l’heure du jour passée et rien envoyé depuis ; un Mac qui dormait l’envoie au réveil.
    public func isDue(now: Date, calendar: Calendar = .current) -> Bool {
        guard isEnabled, let today = time(on: now, calendar: calendar), now >= today else { return false }
        return (lastSentAt ?? .distantPast) < today
    }

    public func next(after now: Date, calendar: Calendar = .current) -> Date? {
        guard isEnabled else { return nil }
        let start = calendar.startOfDay(for: now)
        for offset in 0..<Self.searchDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start),
                  let time = time(on: day, calendar: calendar), time > now else { continue }
            return time
        }
        return nil
    }
}
