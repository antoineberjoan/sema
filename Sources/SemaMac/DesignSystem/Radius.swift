// Rayons d’Espace et forme 1.1 : le rayon grandit avec la surface, et une forme imbriquée retire sa marge au rayon extérieur.
import CoreGraphics

enum Radius {
    /// Tag, highlight, small badge.
    static let mark: CGFloat = 4
    /// Field, clickable icon.
    static let control: CGFloat = 6
    /// List line, tab, callout, image, menu, small card.
    static let block: CGFloat = 10
    /// Window, sheet.
    static let window: CGFloat = 14
    /// Large card, panel.
    static let card: CGFloat = 16
}
