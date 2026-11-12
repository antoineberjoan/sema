// Les jetons motion.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignMotion {
    /// Échelle de départ d'une entrée, avec un fondu ; jamais 0.
    public static let scaleFrom: Double = 0.96
    /// Échelle d'un bouton pendant l'appui.
    public static let pressScale: Double = 0.97
    /// Petit déplacement d'une entrée (un menu qui descend).
    public static let shift: CGFloat = 4
    /// Décalage entre deux éléments, seulement quand l'ordre a un sens.
    public static let stagger: Double = 0.05
    /// Une sortie dure cette part de son entrée.
    public static let exitRatio: Double = 0.6
}
