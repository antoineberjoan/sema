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

    private func utc(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

    @Test func watchedMarketsAreDueOnceACloseHasPassed() {
        // Jeudi 5 novembre 2026 : New York ferme à 16:20 EST, soit 21:20 UTC.
        let beforeClose = utc("2026-11-05T20:00:00Z")
        let afterClose = utc("2026-11-05T22:00:00Z")
        #expect(RefreshPolicy.isDue(syncedAt: beforeClose, now: afterClose, followsCloses: true))
        #expect(!RefreshPolicy.isDue(syncedAt: beforeClose, now: afterClose))
        #expect(!RefreshPolicy.isDue(syncedAt: utc("2026-11-05T21:30:00Z"), now: afterClose, followsCloses: true))
        #expect(RefreshPolicy.lastClose(before: afterClose) == utc("2026-11-05T21:20:00Z"))
    }

    @Test func weekendsHaveNoCloseAndTheNextOneIsMonday() {
        let saturday = utc("2026-11-07T12:00:00Z")
        #expect(RefreshPolicy.lastClose(before: saturday) == utc("2026-11-06T21:20:00Z"))
        #expect(RefreshPolicy.nextClose(after: saturday) == utc("2026-11-09T16:50:00Z"))
        #expect(RefreshPolicy.nextDelay(syncedDates: [saturday], now: saturday, followsCloses: true) == RefreshPolicy.interval)
    }

    @Test func automaticRefreshNeedsAnActiveAndConnectedSource() {
        let rate = MarketSeries(id: "rate", name: "Taux", subtitle: "", category: .savings, unit: .percent, source: "Test", observations: [])
        #expect(RefreshPolicy.isAutomaticallyRefreshable(rate, isSourceEnabled: true, connectedProviders: [], hasWebstatKey: true))
        #expect(!RefreshPolicy.isAutomaticallyRefreshable(rate, isSourceEnabled: true, connectedProviders: [], hasWebstatKey: false))
        #expect(!RefreshPolicy.isAutomaticallyRefreshable(rate, isSourceEnabled: false, connectedProviders: [], hasWebstatKey: true))
    }
}
