// Dimensions et séquence d’ouverture du bandeau, partagées avec son contrôleur AppKit.
import SemaDesign
import SwiftUI

// BANDEAU
//   0 ms  Les favoris en cache sont immédiatement disponibles.
// 200 ms  Le panneau apparaît depuis le bord choisi, sur 4 pt (AppKit) ; il sort en 120 ms.
// 150 ms  Un survol change seulement la profondeur de la carte.
// Le défilement des cartes reste natif, au trackpad et au clavier.
enum MenuRibbonLayout {
    static let cardPadding = DesignSpace.cardInset
    static let height = topPadding + cardHeight + bottomPadding
    static let verticalWidth: CGFloat = 368
    static let signatureHeight = cardHeight
    static let screenInset = DesignSpace.controlInsetDense
    static let padding = DesignSpace.cardInset
    static let topPadding = DesignSpace.controlInsetDense
    static let bottomPadding = DesignSpace.menuInset
    static let headerHeight: CGFloat = 32
    static let headerSpacing = DesignIcon.gap
    static let spacing = DesignSpace.fieldGap
    static let minimumCardWidth: CGFloat = 208
    static let preferredVisibleCards = 4
    /// Cards outside the scroll view: the agenda and the signature.
    static let fixedCards = 2
    static let cardHeight: CGFloat = 216
    static let revealDuration = DesignDuration.standard
    static let dismissDuration = DesignDuration.standard * DesignMotion.exitRatio
    static let hoverDuration = DesignDuration.fast
    static let sparklineWidth: CGFloat = 1.8
    static let revealOffset = DesignMotion.shift

    /// How many favorite cards are visible at this width: the two fixed cards take their share, the minimum card width decides the rest.
    static func visibleCardCount(width: CGFloat, favoriteCount: Int) -> Int {
        let capacity = max(1, Int((width + spacing) / (minimumCardWidth + spacing)) - fixedCards)
        return max(1, min(favoriteCount, capacity, preferredVisibleCards))
    }

    /// The width of each card (favorites and fixed cards share the whole width, with no cap).
    static func cardWidth(width: CGFloat, visibleCount: Int) -> CGFloat {
        (width - CGFloat(visibleCount + fixedCards - 1) * spacing) / CGFloat(visibleCount + fixedCards)
    }
}
