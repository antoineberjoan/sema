// Les jetons ease.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignEase {
    /// Entrée et sortie ; le choix par défaut.
    public static let out: UnitCurve = DesignScale.easeOut
    /// Déplacement ou transformation à l'écran.
    public static let inOut: UnitCurve = DesignScale.easeInOut
    /// Tiroir, à la façon d'iOS.
    public static let drawer: UnitCurve = DesignScale.easeDrawer
    /// Changement de couleur au survol.
    public static let hover: UnitCurve = DesignScale.easeStandard
    /// Mouvement continu : progression, défilement.
    public static let linear: UnitCurve = DesignScale.easeLinear
}
