// Vérifie l’échéance quotidienne à partir du cache, y compris après relance ou changement d’horloge.
import Foundation
import Testing
@testable import MarketCore

struct RefreshPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func cachedSyncStaysFreshForTwentyFourHours() {
        #expect(!RefreshPolicy.isDue(syncedAt: now.addingTimeInterval(-86_399), now: now))
        #expect(RefreshPolicy.isDue(syncedAt: now.addingTimeInterval(-86_400), now: now))
        #expect(RefreshPolicy.isDue(syncedAt: nil, now: now))
    }

    @Test func clockMovingBackwardsCannotBlockRefresh() {
        #expect(RefreshPolicy.isDue(syncedAt: now.addingTimeInterval(60), now: now))
    }

    @Test func nextDeadlineUsesTheOldestSyncInsteadOfRestartTime() {
        let dates: [Date?] = [now.addingTimeInterval(-82_800), now.addingTimeInterval(-3_600)]
        #expect(RefreshPolicy.nextDelay(syncedDates: dates, now: now) == 3_600)
        #expect(RefreshPolicy.nextDelay(syncedDates: dates, now: now.addingTimeInterval(1_800)) == 1_800)
        #expect(RefreshPolicy.nextDelay(syncedDates: [nil], now: now) == 0)
        #expect(RefreshPolicy.nextDelay(syncedDates: [], now: now) == 86_400)
    }
}
