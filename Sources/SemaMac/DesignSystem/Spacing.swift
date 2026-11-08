// Échelle d’espace d’interface d’Espace et forme 1.1 : chaque marge ou écart prend une de ces marches.
import CoreGraphics

enum Spacing {
    /// Between two lines of a tight list.
    static let s2: CGFloat = 2
    /// Inner margin of a tag or a line.
    static let s4: CGFloat = 4
    /// Vertical margin of a small button.
    static let s6: CGFloat = 6
    /// Between an icon and its label; a list line.
    static let s8: CGFloat = 8
    /// Frame around a card.
    static let s10: CGFloat = 10
    /// Inner margin of a menu.
    static let s12: CGFloat = 12
    /// Side margin of a property block.
    static let s14: CGFloat = 14
    /// Inner margin of a card.
    static let s16: CGFloat = 16
    /// Between two groups.
    static let s24: CGFloat = 24
    /// Margin of a narrow page.
    static let s32: CGFloat = 32
    /// Between two sections.
    static let s48: CGFloat = 48
    /// Margin of a wide page.
    static let s64: CGFloat = 64
}
