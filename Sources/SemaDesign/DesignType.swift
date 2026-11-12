// Les rôles de texte : chacun est un ensemble complet (taille, interligne, graisse, approche). Choisir un rôle, ne jamais recomposer.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignType {
    /// Le chiffre principal de l'écran ; au plus un par écran. Taille.
    public static let heroSize: CGFloat = DesignScale.font44
    /// Le chiffre principal de l'écran ; au plus un par écran. Interligne.
    public static let heroLeading: CGFloat = DesignScale.leading46
    /// Le chiffre principal de l'écran ; au plus un par écran. Graisse.
    public static let heroWeight: Font.Weight = DesignScale.weight600
    /// Le chiffre principal de l'écran ; au plus un par écran. Approche.
    public static let heroTracking: Double = DesignScale.trackingTightest
    /// Titre de la page ; un par écran. Taille.
    public static let titleSize: CGFloat = DesignScale.font28
    /// Titre de la page ; un par écran. Interligne.
    public static let titleLeading: CGFloat = DesignScale.leading34
    /// Titre de la page ; un par écran. Graisse.
    public static let titleWeight: Font.Weight = DesignScale.weight500
    /// Titre de la page ; un par écran. Approche.
    public static let titleTracking: Double = DesignScale.trackingTighter
    /// Chiffre d'une tuile. Taille.
    public static let figureSize: CGFloat = DesignScale.font24
    /// Chiffre d'une tuile. Interligne.
    public static let figureLeading: CGFloat = DesignScale.leading28
    /// Chiffre d'une tuile. Graisse.
    public static let figureWeight: Font.Weight = DesignScale.weight600
    /// Chiffre d'une tuile. Approche.
    public static let figureTracking: Double = DesignScale.trackingTighter
    /// Titre d'un groupe de contenus, d'une section ou d'un dialogue. Taille.
    public static let sectionSize: CGFloat = DesignScale.font19
    /// Titre d'un groupe de contenus, d'une section ou d'un dialogue. Interligne.
    public static let sectionLeading: CGFloat = DesignScale.leading24
    /// Titre d'un groupe de contenus, d'une section ou d'un dialogue. Graisse.
    public static let sectionWeight: Font.Weight = DesignScale.weight500
    /// Titre d'un groupe de contenus, d'une section ou d'un dialogue. Approche.
    public static let sectionTracking: Double = DesignScale.trackingTight
    /// Le nom compact du projet ; jamais un titre de page. Taille.
    public static let wordmarkSize: CGFloat = DesignScale.font17
    /// Le nom compact du projet ; jamais un titre de page. Interligne.
    public static let wordmarkLeading: CGFloat = DesignScale.leading20
    /// Le nom compact du projet ; jamais un titre de page. Graisse.
    public static let wordmarkWeight: Font.Weight = DesignScale.weight600
    /// Le nom compact du projet ; jamais un titre de page. Approche.
    public static let wordmarkTracking: Double = DesignScale.trackingTightest
    /// Courte introduction éditoriale ; pas un texte d'interface permanent. Taille.
    public static let ledeSize: CGFloat = DesignScale.font17
    /// Courte introduction éditoriale ; pas un texte d'interface permanent. Interligne.
    public static let ledeLeading: CGFloat = DesignScale.leading28
    /// Courte introduction éditoriale ; pas un texte d'interface permanent. Graisse.
    public static let ledeWeight: Font.Weight = DesignScale.weight400
    /// Courte introduction éditoriale ; pas un texte d'interface permanent. Approche.
    public static let ledeTracking: Double = DesignScale.trackingTight
    /// Un niveau à l'intérieur d'une section ; pas un nom de carte. Taille.
    public static let subheadingSize: CGFloat = DesignScale.font16
    /// Un niveau à l'intérieur d'une section ; pas un nom de carte. Interligne.
    public static let subheadingLeading: CGFloat = DesignScale.leading24
    /// Un niveau à l'intérieur d'une section ; pas un nom de carte. Graisse.
    public static let subheadingWeight: Font.Weight = DesignScale.weight500
    /// Un niveau à l'intérieur d'une section ; pas un nom de carte. Approche.
    public static let subheadingTracking: Double = DesignScale.trackingTight
    /// Titre d'une carte ou d'un élément de liste. Taille.
    public static let headingSize: CGFloat = DesignScale.font15
    /// Titre d'une carte ou d'un élément de liste. Interligne.
    public static let headingLeading: CGFloat = DesignScale.leading20
    /// Titre d'une carte ou d'un élément de liste. Graisse.
    public static let headingWeight: Font.Weight = DesignScale.weight500
    /// Titre d'une carte ou d'un élément de liste. Approche.
    public static let headingTracking: Double = DesignScale.trackingNormal
    /// Texte courant. Taille.
    public static let bodySize: CGFloat = DesignScale.font15
    /// Texte courant. Interligne.
    public static let bodyLeading: Double = DesignScale.leadingReading
    /// Texte courant. Graisse.
    public static let bodyWeight: Font.Weight = DesignScale.weight400
    /// Texte courant. Approche.
    public static let bodyTracking: Double = DesignScale.trackingNormal
    /// Bouton, onglet, libellé ou champ. Taille.
    public static let labelSize: CGFloat = DesignScale.font14
    /// Bouton, onglet, libellé ou champ. Interligne.
    public static let labelLeading: CGFloat = DesignScale.leading20
    /// Bouton, onglet, libellé ou champ. Graisse.
    public static let labelWeight: Font.Weight = DesignScale.weight500
    /// Bouton, onglet, libellé ou champ. Approche.
    public static let labelTracking: Double = DesignScale.trackingTight
    /// Détail sous un titre. Taille.
    public static let smallSize: CGFloat = DesignScale.font13
    /// Détail sous un titre. Interligne.
    public static let smallLeading: CGFloat = DesignScale.leading18
    /// Détail sous un titre. Graisse.
    public static let smallWeight: Font.Weight = DesignScale.weight400
    /// Détail sous un titre. Approche.
    public static let smallTracking: Double = DesignScale.trackingNormal
    /// Unité, date, axe ou aide sous un champ. Taille.
    public static let captionSize: CGFloat = DesignScale.font13
    /// Unité, date, axe ou aide sous un champ. Interligne.
    public static let captionLeading: CGFloat = DesignScale.leading18
    /// Unité, date, axe ou aide sous un champ. Graisse.
    public static let captionWeight: Font.Weight = DesignScale.weight400
    /// Unité, date, axe ou aide sous un champ. Approche.
    public static let captionTracking: Double = DesignScale.trackingWide
    /// Code, avec la famille monospace. Taille.
    public static let codeSize: CGFloat = DesignScale.font13
    /// Code, avec la famille monospace. Interligne.
    public static let codeLeading: CGFloat = DesignScale.leading20
    /// Code, avec la famille monospace. Graisse.
    public static let codeWeight: Font.Weight = DesignScale.weight400
    /// Code, avec la famille monospace. Approche.
    public static let codeTracking: Double = DesignScale.trackingNormal
    /// Surtitre discret, en casse de phrase. Taille.
    public static let overlineSize: CGFloat = DesignScale.font12
    /// Surtitre discret, en casse de phrase. Interligne.
    public static let overlineLeading: CGFloat = DesignScale.leading18
    /// Surtitre discret, en casse de phrase. Graisse.
    public static let overlineWeight: Font.Weight = DesignScale.weight500
    /// Surtitre discret, en casse de phrase. Approche.
    public static let overlineTracking: Double = DesignScale.trackingWider
    /// Mot court dans une pastille ; jamais une phrase. Taille.
    public static let tagSize: CGFloat = DesignScale.font12
    /// Mot court dans une pastille ; jamais une phrase. Interligne.
    public static let tagLeading: CGFloat = DesignScale.leading16
    /// Mot court dans une pastille ; jamais une phrase. Graisse.
    public static let tagWeight: Font.Weight = DesignScale.weight400
    /// Mot court dans une pastille ; jamais une phrase. Approche.
    public static let tagTracking: Double = DesignScale.trackingNormal
    /// Métadonnée compacte ; jamais une phrase. Taille.
    public static let microSize: CGFloat = DesignScale.font1152
    /// Métadonnée compacte ; jamais une phrase. Interligne.
    public static let microLeading: CGFloat = DesignScale.leading14
    /// Métadonnée compacte ; jamais une phrase. Graisse.
    public static let microWeight: Font.Weight = DesignScale.weight400
    /// Métadonnée compacte ; jamais une phrase. Approche.
    public static let microTracking: Double = DesignScale.trackingWide
    /// Emphase dans le texte ; ne pas mettre tous les titres en gras.
    public static let emphasisWeight: Font.Weight = DesignScale.weight600
    /// Texte d'un champ au toucher : 16 px évitent le zoom d'iOS pendant la saisie.
    public static let fieldTouchSize: CGFloat = DesignScale.font16
}
