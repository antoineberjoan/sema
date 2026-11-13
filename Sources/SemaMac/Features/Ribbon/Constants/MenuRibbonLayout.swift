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
    static let height = topPadding + DesignLayout.menuRibbonCardHeight + bottomPadding
    static let signatureHeight = DesignLayout.menuRibbonCardHeight
    static let screenInset = DesignSpace.controlInsetDense
    static let padding = DesignSpace.cardInset
    static let topPadding = DesignSpace.controlInsetDense
    static let bottomPadding = DesignSpace.menuInset
    static let headerSpacing = DesignIcon.gap
    static let spacing = DesignSpace.fieldGap
    static let revealDuration = DesignDuration.standard
    static let dismissDuration = DesignDuration.standard * DesignMotion.exitRatio
    static let hoverDuration = DesignDuration.fast
    static let revealOffset = DesignMotion.shift

    /// Combien de cartes favorites sont visibles à cette largeur : les deux cartes fixes prennent leur part, la largeur minimale d’une carte décide du reste.
    static func visibleCardCount(width: CGFloat, favoriteCount: Int) -> Int {
        let capacity = max(1, Int((width + spacing) / (DesignLayout.menuRibbonMinimumCardWidth + spacing)) - Int(DesignMeasure.menuRibbonFixedCards))
        return max(1, min(favoriteCount, capacity, Int(DesignMeasure.menuRibbonPreferredVisibleCards)))
    }

    /// La largeur de chaque carte (favoris et cartes fixes se partagent toute la largeur, sans plafond).
    static func cardWidth(width: CGFloat, visibleCount: Int) -> CGFloat {
        (width - CGFloat(visibleCount + Int(DesignMeasure.menuRibbonFixedCards) - 1) * spacing) / CGFloat(visibleCount + Int(DesignMeasure.menuRibbonFixedCards))
    }
}
