// Les jetons opacity.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignOpacity {
    /// Opacité d'un contrôle désactivé ; pas pour un texte secondaire (text-muted).
    public static let disabled: Double = 0.5
    /// Le fond d'un élément au repos posé sur le verre (un badge, un champ) : la couleur du texte à cette opacité. Pas pour un fond plein.
    public static let glassRest: Double = 0.035
    /// Le fond d'un élément survolé posé sur le verre : la couleur du texte à cette opacité. Pas pour un fond plein.
    public static let glassHover: Double = 0.04
}
