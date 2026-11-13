// Définit la fraîcheur des séries : une fois par jour, et après chaque clôture pour les repères surveillés.
import Foundation

public enum RefreshPolicy {
    public static let interval: TimeInterval = 24 * 60 * 60

    /// Clôtures des jours ouvrés après lesquelles les marchés surveillés sont vérifiés, avec un court délai pour que les fournisseurs publient.
    private static let closes: [(timeZone: TimeZone, hour: Int, minute: Int)] = [
        (TimeZone(identifier: "Europe/Paris")!, 17, 50),
        (TimeZone(identifier: "America/New_York")!, 16, 20),
    ]
    /// Jours cherchés autour d’une date pour trouver la clôture ouvrée la plus proche.
    private static let searchDays = 7

    /// Une série est due après 24 h, ou, quand elle est surveillée pour les mouvements inhabituels, dès qu’une clôture est passée depuis sa synchronisation.
    public static func isDue(syncedAt: Date?, now: Date, followsCloses: Bool = false) -> Bool {
        guard let syncedAt else { return true }
        let age = now.timeIntervalSince(syncedAt)
        if age < 0 || age >= interval { return true }
        guard followsCloses, let close = lastClose(before: now) else { return false }
        return close > syncedAt
    }

    public static func nextDelay(syncedDates: [Date?], now: Date, followsCloses: Bool = false) -> TimeInterval {
        let daily = syncedDates.map { date in
            guard let date, !isDue(syncedAt: date, now: now) else { return 0 }
            return date.addingTimeInterval(interval).timeIntervalSince(now)
        }.min() ?? interval
        guard followsCloses, let close = nextClose(after: now) else { return daily }
        return min(daily, close.timeIntervalSince(now))
    }

    public static func lastClose(before date: Date) -> Date? {
        closeDates(around: date, offsets: Array((0...searchDays).map { -$0 })).filter { $0 <= date }.max()
    }

    public static func nextClose(after date: Date) -> Date? {
        closeDates(around: date, offsets: Array(0...searchDays)).filter { $0 > date }.min()
    }

    private static func closeDates(around date: Date, offsets: [Int]) -> [Date] {
        closes.flatMap { close -> [Date] in
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = close.timeZone
            return offsets.compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: offset, to: date),
                      !calendar.isDateInWeekend(day) else { return nil }
                return calendar.date(bySettingHour: close.hour, minute: close.minute, second: 0, of: day)
            }
        }
    }
}
