// Dimensions et séquence d’ouverture du bandeau, partagées avec son contrôleur AppKit.
import SwiftUI

// BANDEAU
//   0 ms  Les favoris en cache sont immédiatement disponibles.
// 200 ms  Le panneau apparaît depuis le bord choisi, sur 4 pt (AppKit) ; il sort en 120 ms.
// 150 ms  Un survol change seulement la profondeur de la carte.
// Le défilement des cartes reste natif, au trackpad et au clavier.
enum MenuRibbonLayout {
    static let cardPadding = Spacing.s16
    static let height = topPadding + cardHeight + bottomPadding
    static let verticalWidth: CGFloat = 368
    static let signatureHeight = cardHeight
    static let screenInset = Spacing.s6
    static let padding = Spacing.s16
    static let topPadding = Spacing.s6
    static let bottomPadding = Spacing.s12
    static let headerHeight: CGFloat = 32
    static let headerSpacing = Spacing.s6
    static let spacing = Spacing.s12
    static let minimumCardWidth: CGFloat = 208
    static let preferredVisibleCards = 4
    static let cardHeight: CGFloat = 216
    static let controlColumnWidth: CGFloat = 84
    static let periodRowHeight: CGFloat = 24
    static let controlColumnPadding = Spacing.s8
    static let revealDuration = Motion.standard
    static let dismissDuration = Motion.standard * Motion.exitRatio
    static let hoverDuration = Motion.fast
    static let sparklineWidth: CGFloat = 1.8
    static let revealOffset = Motion.shift
}
