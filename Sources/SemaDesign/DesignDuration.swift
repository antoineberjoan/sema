// Les jetons duration.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignDuration {
    /// Action fréquente ou au clavier : pas d'animation.
    public static let instant: Double = DesignScale.duration0
    /// Retour de pression d'un bouton.
    public static let press: Double = DesignScale.duration120
    /// Survol, changement de couleur, infobulle.
    public static let fast: Double = DesignScale.duration150
    /// Menu, liste déroulante.
    public static let standard: Double = DesignScale.duration200
    /// Fenêtre, tiroir, panneau.
    public static let wide: Double = DesignScale.duration300
    /// Explication, accueil, page vue une fois ; jamais sur une interface fréquente.
    public static let explain: Double = DesignScale.duration550
}
