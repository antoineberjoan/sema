// Vérifie la fenêtre et l’ordre des communiqués montrés avec une séance.
import Foundation
import Testing
@testable import MarketCore

struct PressReleaseWindowTests {
    private let start = Date(timeIntervalSince1970: 1_792_022_400)

    private func release(_ title: String, after seconds: TimeInterval) -> PressRelease {
        PressRelease(feed: CentralBankFeed.allCases[0], title: title, link: URL(string: "https://example.com/\(title)")!,
                     publishedAt: start.addingTimeInterval(seconds))
    }

    @Test func recentKeepsTheWindowAndOrdersNewestFirst() {
        let all = [release("old", after: -10), release("a", after: 10), release("b", after: 20)]
        let kept = PressRelease.recent(all, from: start, to: start.addingTimeInterval(20))
        #expect(kept.map(\.title) == ["b", "a"])
    }
}
