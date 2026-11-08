// Réglages du brief du matin : activation, heure locale, jours ouvrés et dernier envoi, pour l’envoyer une fois par jour.
import Foundation

public struct BriefPreferences: Codable, Equatable, Sendable {
    public static let defaultHour = 8
    public static let defaultMinute = 0
    /// Days scanned to find the next allowed day; a week always contains one.
    private static let searchDays = 8

    public var isEnabled = false
    public var hour = BriefPreferences.defaultHour
    public var minute = BriefPreferences.defaultMinute
    public var weekdaysOnly = true
    public var lastSentAt: Date?

    public init() {}

    /// Time of the brief on the calendar day of `date`, or nil on a weekend when only weekdays are chosen.
    public func time(on date: Date, calendar: Calendar = .current) -> Date? {
        if weekdaysOnly, calendar.isDateInWeekend(date) { return nil }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
    }

    /// Due once today's time has passed and nothing was sent since; a Mac that slept sends it on wake.
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
