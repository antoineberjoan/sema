// Définit la fraîcheur quotidienne des séries sans confondre synchronisation et publication.
import Foundation

public enum RefreshPolicy {
    public static let interval: TimeInterval = 24 * 60 * 60

    public static func isDue(syncedAt: Date?, now: Date) -> Bool {
        guard let syncedAt else { return true }
        let age = now.timeIntervalSince(syncedAt)
        return age < 0 || age >= interval
    }

    public static func nextDelay(syncedDates: [Date?], now: Date) -> TimeInterval {
        syncedDates.map { date in
            guard let date, !isDue(syncedAt: date, now: now) else { return 0 }
            return date.addingTimeInterval(interval).timeIntervalSince(now)
        }.min() ?? interval
    }
}
