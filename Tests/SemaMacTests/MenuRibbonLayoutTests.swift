// Vérifie combien de cartes de favoris le bandeau montre selon sa largeur, et que les cartes se partagent toute la largeur.
import CoreGraphics
import SemaDesign
import Testing
@testable import SemaMac

struct MenuRibbonLayoutTests {
    @Test func fourFavoritesAreVisibleOnAWideScreen() {
        #expect(Int(DesignMeasure.menuRibbonPreferredVisibleCards) == 4)
        #expect(MenuRibbonLayout.visibleCardCount(width: 1_500, favoriteCount: 6) == 4)
    }

    @Test func neverMoreThanFourEvenOnAVeryWideScreen() {
        #expect(MenuRibbonLayout.visibleCardCount(width: 3_000, favoriteCount: 10) == 4)
    }

    @Test func theMinimumCardWidthDecidesHowManyFit() {
        #expect(DesignLayout.menuRibbonMinimumCardWidth == 208)
        #expect(Int(DesignMeasure.menuRibbonFixedCards) == 2)
        // 1 000 pt : floor(1 012 / 220) = 4 emplacements, dont deux pris par l’agenda et la signature.
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
        let slots = visible + Int(DesignMeasure.menuRibbonFixedCards)
        let total = card * CGFloat(slots) + MenuRibbonLayout.spacing * CGFloat(slots - 1)
        #expect(abs(total - width) < 0.001)
        #expect(card >= DesignLayout.menuRibbonMinimumCardWidth)
    }
}
