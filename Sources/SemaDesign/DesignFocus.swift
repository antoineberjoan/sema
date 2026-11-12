// Les jetons focus.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignFocus {
    /// Épaisseur de l'anneau de focus au clavier ; jamais retiré.
    public static let width: CGFloat = 2
    /// Écart entre l'anneau de focus et le contrôle, pour qu'il se lise sur tous les fonds.
    public static let offset: CGFloat = 2
}
