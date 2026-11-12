// Vérifie combien de cartes de favoris le bandeau montre selon sa largeur, et que les cartes se partagent toute la largeur.
import CoreGraphics
import Testing
@testable import SemaMac

struct MenuRibbonLayoutTests {
    @Test func fourFavoritesAreVisibleOnAWideScreen() {
        #expect(MenuRibbonLayout.preferredVisibleCards == 4)
        #expect(MenuRibbonLayout.visibleCardCount(width: 1_500, favoriteCount: 6) == 4)
    }

    @Test func neverMoreThanFourEvenOnAVeryWideScreen() {
        #expect(MenuRibbonLayout.visibleCardCount(width: 3_000, favoriteCount: 10) == 4)
    }

    @Test func theMinimumCardWidthDecidesHowManyFit() {
        #expect(MenuRibbonLayout.minimumCardWidth == 208)
        #expect(MenuRibbonLayout.fixedCards == 2)
        // 1 000 pt: floor(1 012 / 220) = 4 slots, two taken by the agenda and the signature.
        #expect(MenuRibbonLayout.visibleCardCount(width: 1_000, favoriteCount: 6) == 2)
    }

    @Test func atLeastOneFavoriteStaysVisibleOnASmallWidth() {
        #expect(MenuRibbonLayout.visibleCardCount(width: 300, favoriteCount: 6) == 1)
    }

    @Test func fewerFavoritesThanSlotsShowOnlyThem() {
        #expect(MenuRibbonLayout.visibleCardCount(width: 1_500, favoriteCount: 2) == 2)
    }

    @Test func cardsShareTheWholeWidthWithoutACap() {
        let width: CGFloat = 1_500
        let visible = MenuRibbonLayout.visibleCardCount(width: width, favoriteCount: 6)
        let card = MenuRibbonLayout.cardWidth(width: width, visibleCount: visible)
        let total = card * CGFloat(visible + MenuRibbonLayout.fixedCards) + MenuRibbonLayout.spacing * CGFloat(visible + MenuRibbonLayout.fixedCards - 1)
        #expect(abs(total - width) < 0.001)
        #expect(card >= MenuRibbonLayout.minimumCardWidth)
    }
}
