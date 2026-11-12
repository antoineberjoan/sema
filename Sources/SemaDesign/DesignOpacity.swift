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
    /// Propre à sema : l'opacité de l'accent en haut à gauche du dégradé de la signature du bandeau, posé sur un fond noir.
    public static let signatureGradientTop: Double = 0.85
    /// Propre à sema : l'opacité de l'accent en bas à droite du dégradé de la signature du bandeau.
    public static let signatureGradientBottom: Double = 0.65
    /// Propre à sema : l'opacité du texte de contexte posé sur le dégradé de la signature (on-accent à cette opacité).
    public static let signatureContextText: Double = 0.85
    /// Propre à sema : le fond du bouton d'idée ou de bug posé sur le dégradé de la signature (on-accent à cette opacité).
    public static let signatureFeedbackFill: Double = 0.12
    /// Propre à sema : l'opacité du bord clair de la signature, en haut à gauche (on-accent à cette opacité).
    public static let signatureEdgeTop: Double = 0.22
    /// Propre à sema : l'opacité du bord clair de la signature, en bas à droite (on-accent à cette opacité).
    public static let signatureEdgeBottom: Double = 0.03
}
