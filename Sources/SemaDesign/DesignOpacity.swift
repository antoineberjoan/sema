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
    /// Propre à sema : le voile de contraste du verre en mode sombre, avant le réglage de transparence.
    public static let glassVeilDark: Double = 0.1
    /// Propre à sema : le voile de contraste du verre en mode clair, avant le réglage de transparence.
    public static let glassVeilLight: Double = 0.2
    /// Propre à sema : la teinte du verre en mode sombre, avant le réglage de teinte.
    public static let glassTintDark: Double = 0.22
    /// Propre à sema : la teinte du verre en mode clair, avant le réglage de teinte.
    public static let glassTintLight: Double = 0.12
    /// Propre à sema : la teinte du verre à l'extrémité basse de son dégradé, avant le réglage de teinte.
    public static let glassTintEnd: Double = 0.08
    /// Propre à sema : la teinte du repli opaque (Réduire la transparence).
    public static let glassTintOpaque: Double = 0.06
    /// Propre à sema : le reflet clair d'une carte au repos.
    public static let glassHighlightRest: Double = 0.025
    /// Propre à sema : le reflet clair d'une carte survolée.
    public static let glassHighlightEmphasized: Double = 0.07
    /// Propre à sema : le bord clair du verre en mode sombre, en haut à gauche.
    public static let glassEdgeDark: Double = 0.16
    /// Propre à sema : le bord clair du verre en mode clair, en haut à gauche.
    public static let glassEdgeLight: Double = 0.65
    /// Propre à sema : le bord clair du verre en bas à droite.
    public static let glassEdgeEnd: Double = 0.025
    /// Propre à sema : l'opacité du grain quand son réglage est au maximum.
    public static let glassGrainMax: Double = 0.16
    /// Propre à sema : area opacity, RibbonCard (opacité).
    public static let ribbonCardAreaOpacity: Double = 0.14
    /// Propre à sema : area opacity, HistoryChart (opacité).
    public static let historyChartAreaOpacity: Double = 0.09
    /// Propre à sema : pressed opacity, Press (opacité).
    public static let pressPressedOpacity: Double = 0.82
}
