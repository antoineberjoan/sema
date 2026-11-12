// Les élévations : peu de niveaux ; la plupart des surfaces restent plates (aucune ombre).
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignElevation {
    /// Niveau 1, posé : une carte qu'on peut déplacer (kanban) ; pas une carte de lecture.
    public static let raised: [ShadowLayer] = [
        ShadowLayer(color: DesignColor.shadowNear, x: 0, y: 1, blur: 2, spread: 0),
    ]
    /// Niveau 2, flottant : menu, popover, infobulle. Valeur de départ, à régler sur un vrai écran.
    public static let floating: [ShadowLayer] = [
        ShadowLayer(color: DesignColor.shadowNear, x: 0, y: 1, blur: 2, spread: 0),
        ShadowLayer(color: DesignColor.shadowFar, x: 0, y: 8, blur: 24, spread: 0),
    ]
    /// Niveau 3, fenêtre : fenêtre modale, invite, avec le voile scrim. Valeur de départ, à régler sur un vrai écran.
    public static let window: [ShadowLayer] = [
        ShadowLayer(color: DesignColor.shadowNear, x: 0, y: 2, blur: 8, spread: 0),
        ShadowLayer(color: DesignColor.shadowFar, x: 0, y: 24, blur: 64, spread: 0),
    ]
}
