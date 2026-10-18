// Dimensions et séquence d’ouverture du bandeau, partagées avec son contrôleur AppKit.
import SwiftUI

// BANDEAU
//   0 ms  Les favoris en cache sont immédiatement disponibles.
// 220 ms  Le panneau apparaît depuis le bord choisi, sur 8 pt (AppKit).
// 160 ms  Un survol change seulement la profondeur de la carte.
// Le défilement des cartes reste natif, au trackpad et au clavier.
enum MenuRibbonLayout {
    static let cardPadding: CGFloat = 16
    static let height = topPadding + cardHeight + bottomPadding
    static let verticalWidth: CGFloat = 368
    static let signatureHeight = cardHeight
    static let screenInset: CGFloat = 6
    static let padding: CGFloat = 18
    static let topPadding: CGFloat = 6
    static let bottomPadding: CGFloat = 12
    static let headerHeight: CGFloat = 32
    static let headerSpacing: CGFloat = 6
    static let spacing: CGFloat = 12
    static let minimumCardWidth: CGFloat = 208
    static let preferredVisibleCards = 4
    static let cardHeight: CGFloat = 216
    static let controlColumnWidth: CGFloat = 84
    static let periodRowHeight: CGFloat = 24
    static let controlColumnPadding: CGFloat = 8
    static let revealDuration = 0.22
    static let dismissDuration = 0.13
    static let hoverDuration = 0.16
    static let emptySymbolFont = Font.system(size: 24, weight: .light)
    static let valueFont = Font.system(size: 32, weight: .medium)
    static let sparklineWidth: CGFloat = 1.8
    static let revealOffset: CGFloat = 8
}
