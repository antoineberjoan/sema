// Le rythme du texte, en rem : il suit la taille du texte, pas l'interface.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignRhythm {
    /// Entre deux paragraphes.
    public static let paragraph: CGFloat = 14.4
    /// Au-dessus d'un titre.
    public static let beforeHeading: CGFloat = 48
    /// Sous un titre de section.
    public static let afterSection: CGFloat = 16
    /// Sous un sous-titre.
    public static let afterSubheading: CGFloat = 12
    /// Retrait d'une citation.
    public static let indent: CGFloat = 24
}
