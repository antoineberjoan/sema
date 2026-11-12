// Les rôles d'espace : un usage chacun. Un composant qui a besoin d'un autre usage ajoute un rôle, pas une valeur.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignSpace {
    /// Entre deux lignes d'une liste serrée ; pas entre deux groupes.
    public static let listGapDense: CGFloat = DesignScale.space2
    /// Marge intérieure d'une pastille ou d'un tag.
    public static let markInset: CGFloat = DesignScale.space4
    /// Marge verticale d'un petit bouton ou d'un contrôle compact.
    public static let controlInsetDense: CGFloat = DesignScale.space6
    /// Marge intérieure d'une ligne de liste.
    public static let rowInset: CGFloat = DesignScale.space8
    /// Marge d'un cadre autour d'une carte.
    public static let frameInset: CGFloat = DesignScale.space10
    /// Marge intérieure d'un menu.
    public static let menuInset: CGFloat = DesignScale.space12
    /// Marge latérale d'un bloc de propriétés.
    public static let panelInsetInline: CGFloat = DesignScale.space14
    /// Marge intérieure d'une carte.
    public static let cardInset: CGFloat = DesignScale.space16
    /// Entre deux groupes d'une même section.
    public static let groupGap: CGFloat = DesignScale.space24
    /// Marge d'une page étroite.
    public static let pageInsetNarrow: CGFloat = DesignScale.space32
    /// Entre deux sections.
    public static let sectionGap: CGFloat = DesignScale.space48
    /// Marge d'une page large.
    public static let pageInsetWide: CGFloat = DesignScale.space64
}
