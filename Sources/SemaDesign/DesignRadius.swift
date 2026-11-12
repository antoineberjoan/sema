// Les rayons : le rayon grandit avec la surface.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignRadius {
    /// Tag, surlignage, pastille.
    public static let mark: CGFloat = DesignScale.radius4
    /// Champ, bouton, icône cliquable.
    public static let control: CGFloat = DesignScale.radius6
    /// Ligne de liste, onglet, callout, image, menu, petite carte.
    public static let block: CGFloat = DesignScale.radius10
    /// Fenêtre, invite.
    public static let window: CGFloat = DesignScale.radius14
    /// Grande carte, panneau.
    public static let card: CGFloat = DesignScale.radius16
}
