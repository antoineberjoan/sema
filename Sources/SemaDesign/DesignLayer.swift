// Les couches (z-index), nommées : jamais un nombre écrit dans un composant.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignLayer {
    /// Barre ou en-tête collé au défilement.
    public static let sticky: Double = 10
    /// Menu, liste déroulante, popover.
    public static let menu: Double = 20
    /// Voile d'une fenêtre modale.
    public static let overlay: Double = 30
    /// Fenêtre modale, invite.
    public static let modal: Double = 40
    /// Notification passagère, au-dessus de tout.
    public static let toast: Double = 50
}
