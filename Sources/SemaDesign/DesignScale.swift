// Les valeurs brutes. Seuls les rôles les lisent ; un composant ne lit jamais une primitive.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

enum DesignScale {
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space2: CGFloat = 2
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space4: CGFloat = 4
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space6: CGFloat = 6
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space8: CGFloat = 8
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space10: CGFloat = 10
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space12: CGFloat = 12
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space14: CGFloat = 14
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space16: CGFloat = 16
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space24: CGFloat = 24
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space32: CGFloat = 32
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space48: CGFloat = 48
    /// L'échelle d'espace d'interface : pas de 2 px jusqu'à 16, puis des pas plus larges.
    static let space64: CGFloat = 64
    /// L'échelle des rayons : peu de pas, les mêmes partout.
    static let radius4: CGFloat = 4
    /// L'échelle des rayons : peu de pas, les mêmes partout.
    static let radius6: CGFloat = 6
    /// L'échelle des rayons : peu de pas, les mêmes partout.
    static let radius10: CGFloat = 10
    /// L'échelle des rayons : peu de pas, les mêmes partout.
    static let radius14: CGFloat = 14
    /// L'échelle des rayons : peu de pas, les mêmes partout.
    static let radius16: CGFloat = 16
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font12: CGFloat = 12
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font13: CGFloat = 13
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font14: CGFloat = 14
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font15: CGFloat = 15
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font16: CGFloat = 16
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font17: CGFloat = 17
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font19: CGFloat = 19
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font24: CGFloat = 24
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font26: CGFloat = 26
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font28: CGFloat = 28
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font44: CGFloat = 44
    /// Les tailles de texte, en rem : toute l'échelle suit la taille choisie par le lecteur.
    static let font1152: CGFloat = 11.52
    /// Les interlignes d'interface, en rem, serrés et fixes.
    static let leading14: CGFloat = 14
    /// Les interlignes d'interface, en rem, serrés et fixes.
    static let leading16: CGFloat = 16
    /// Les interlignes d'interface, en rem, serrés et fixes.
    static let leading18: CGFloat = 18
    /// Les interlignes d'interface, en rem, serrés et fixes.
    static let leading20: CGFloat = 20
    /// Les interlignes d'interface, en rem, serrés et fixes.
    static let leading24: CGFloat = 24
    /// Les interlignes d'interface, en rem, serrés et fixes.
    static let leading28: CGFloat = 28
    /// Les interlignes d'interface, en rem, serrés et fixes.
    static let leading34: CGFloat = 34
    /// Les interlignes d'interface, en rem, serrés et fixes.
    static let leading46: CGFloat = 46
    /// L'interligne de lecture, un rapport : il suit la taille du texte.
    static let leadingReading: Double = 1.75
    /// Les graisses : lecture, titres, chiffres et emphase.
    static let weight400: Font.Weight = .regular
    /// Les graisses : lecture, titres, chiffres et emphase.
    static let weight500: Font.Weight = .medium
    /// Les graisses : lecture, titres, chiffres et emphase.
    static let weight600: Font.Weight = .semibold
    /// L'approche, en em : négative quand le texte grandit, un peu positive sur le plus petit texte.
    static let trackingTightest: Double = -0.03
    /// L'approche, en em : négative quand le texte grandit, un peu positive sur le plus petit texte.
    static let trackingTighter: Double = -0.02
    /// L'approche, en em : négative quand le texte grandit, un peu positive sur le plus petit texte.
    static let trackingTight: Double = -0.01
    /// L'approche, en em : négative quand le texte grandit, un peu positive sur le plus petit texte.
    static let trackingNormal: Double = 0
    /// L'approche, en em : négative quand le texte grandit, un peu positive sur le plus petit texte.
    static let trackingWide: Double = 0.01
    /// L'approche, en em : négative quand le texte grandit, un peu positive sur le plus petit texte.
    static let trackingWider: Double = 0.05
    /// Les durées : courtes en interface, plus longues pour une grande surface ou une explication.
    static let duration0: Double = 0
    /// Les durées : courtes en interface, plus longues pour une grande surface ou une explication.
    static let duration120: Double = 0.12
    /// Les durées : courtes en interface, plus longues pour une grande surface ou une explication.
    static let duration150: Double = 0.15
    /// Les durées : courtes en interface, plus longues pour une grande surface ou une explication.
    static let duration200: Double = 0.2
    /// Les durées : courtes en interface, plus longues pour une grande surface ou une explication.
    static let duration300: Double = 0.3
    /// Les durées : courtes en interface, plus longues pour une grande surface ou une explication.
    static let duration550: Double = 0.55
    /// Les courbes (Emil Kowalski, licence MIT) : jamais d'accélération seule sur l'interface.
    static let easeOut: UnitCurve = .bezier(startControlPoint: UnitPoint(x: 0.23, y: 1), endControlPoint: UnitPoint(x: 0.32, y: 1))
    /// Les courbes (Emil Kowalski, licence MIT) : jamais d'accélération seule sur l'interface.
    static let easeInOut: UnitCurve = .bezier(startControlPoint: UnitPoint(x: 0.77, y: 0), endControlPoint: UnitPoint(x: 0.175, y: 1))
    /// Les courbes (Emil Kowalski, licence MIT) : jamais d'accélération seule sur l'interface.
    static let easeDrawer: UnitCurve = .bezier(startControlPoint: UnitPoint(x: 0.32, y: 0.72), endControlPoint: UnitPoint(x: 0, y: 1))
    /// Les courbes (Emil Kowalski, licence MIT) : jamais d'accélération seule sur l'interface.
    static let easeStandard: UnitCurve = .bezier(startControlPoint: UnitPoint(x: 0.25, y: 0.1), endControlPoint: UnitPoint(x: 0.25, y: 1))
    /// Les courbes (Emil Kowalski, licence MIT) : jamais d'accélération seule sur l'interface.
    static let easeLinear: UnitCurve = .bezier(startControlPoint: UnitPoint(x: 0, y: 0), endControlPoint: UnitPoint(x: 1, y: 1))
}
