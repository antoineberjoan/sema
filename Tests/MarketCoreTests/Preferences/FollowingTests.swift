// Vérifie ce que deviennent favoris et alertes quand on rejoue le départ, qu'on retire un repère ou qu'on change sa source.
import Foundation
import Testing
@testable import MarketCore

struct FollowingTests {
    private func rule(_ id: String, enabled: Bool = true, checked: Date? = nil) -> AlertRule {
        AlertRule(seriesID: id, direction: .rise, threshold: 1, isEnabled: enabled, condition: .level, lastEvaluatedAt: checked)
    }

    @Test func replayingTheStartKeepsPersonalSeriesAndPausesRemovedStarters() {
        var preferences = AppPreferences(favoriteIDs: ["a", "b", "mine"], alerts: [rule("a"), rule("b"), rule("mine")],
                                         followedSeriesIDs: ["a", "b", "mine"])
        preferences.followStarters(["b", "b", "zzz"], allowed: ["a", "b"])
        #expect(preferences.followedSeriesIDs == ["b", "mine"])
        #expect(preferences.favoriteIDs == ["b", "mine"])
        #expect(preferences.alerts.map(\.isEnabled) == [false, true, true])
    }

    @Test func unfollowingRemovesFavoritesAndPausesTheRulesWithoutDeletingThem() {
        var preferences = AppPreferences(favoriteIDs: ["a", "b"], alerts: [rule("a"), rule("b")], followedSeriesIDs: ["a", "b"])
        preferences.unfollow(["a"])
        #expect(preferences.followedSeriesIDs == ["b"])
        #expect(preferences.favoriteIDs == ["b"])
        #expect(preferences.alerts.count == 2)
        #expect(preferences.alerts.map(\.isEnabled) == [false, true])
    }

    @Test func replacingASourceKeepsOnePlaceTheFavoriteAndTheRules() {
        let older = Date(timeIntervalSince1970: 100)
        let newer = Date(timeIntervalSince1970: 200)
        var preferences = AppPreferences(favoriteIDs: ["old"], alerts: [rule("old", checked: older), rule("other")],
                                         followedSeriesIDs: ["old", "twin", "other"])
        preferences.replacing(["old", "twin"], with: "new", latest: newer)
        #expect(preferences.followedSeriesIDs == ["new", "other"])
        #expect(preferences.favoriteIDs == ["new"])
        #expect(preferences.alerts[0].seriesID == "new")
        #expect(preferences.alerts[0].lastEvaluatedAt == newer)
        #expect(preferences.alerts[1].seriesID == "other")
    }
}
