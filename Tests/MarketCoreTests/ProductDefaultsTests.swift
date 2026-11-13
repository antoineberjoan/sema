// Vérifie les valeurs par défaut que le produit promet à une nouvelle installation : favoris, suivi, raccourcis et fenêtre d'habitude.
import Foundation
import Testing
@testable import MarketCore

struct ProductDefaultsTests {
    @Test func aNewInstallationProposesFourFavoritesAndFollowsNothing() {
        let preferences = AppPreferences()
        #expect(preferences.favoriteIDs == Set(["fr10", "ecb", "eurusd", "livreta"].map(IdentifierMigration.upgrade)))
        #expect(preferences.followedSeriesIDs.isEmpty)
    }

    @Test func standardGlobalShortcutsAreControlOptionBAndControlShiftH() {
        let standard = ShortcutPreferences.standard
        #expect(standard.ribbon == AppShortcut(keyCode: 11, modifiers: [.control, .option], key: "B"))
        #expect(standard.workspace == AppShortcut(keyCode: 4, modifiers: [.control, .shift], key: "H"))
    }

    @Test func quickSearchHasNoGlobalShortcutUntilThePersonChoosesOne() {
        #expect(ShortcutPreferences.standard.search == nil)
    }

    @Test func theUsualMoveIsMeasuredOnTheTwentyPreviousSessions() {
        #expect(UnusualMove.window == 20)
    }

    @Test func sensitivitiesAreThreeTwoAndOneAndAHalfTimesTheUsual() {
        #expect(MoveSensitivity.allCases.map(\.multiplier) == [3, 2, 1.5])
    }

    @Test func theBriefIsDueAtEightOnWeekdaysByDefault() {
        let brief = BriefPreferences()
        #expect(brief.hour == 8 && brief.minute == 0)
        #expect(brief.isWeekdaysOnly)
        #expect(!brief.isEnabled)
    }

    @Test func dataStaysFreshForTwentyFourHours() {
        #expect(RefreshPolicy.interval == 24 * 60 * 60)
    }

    @Test func atMostThreeSentencesOfASummaryAreShown() {
        #expect(SummaryCheck.maximumSentences == 3)
    }
}
