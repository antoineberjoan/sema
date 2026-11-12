// Les rôles de couleur, en clair ($value) et en sombre (dark). Les composants ne lisent que ces rôles.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public enum DesignColor {
    /// Fond de la fenêtre ou de la page ; pas pour une carte posée dessus (surface-raised).
    public static let background: Color = makeAdaptive(light: DesignPrimitive.paper0, dark: DesignPrimitive.ink800)
    /// Zone posée sur le fond : barre latérale, panneau, champ ; pas pour une carte qui flotte.
    public static let surface: Color = makeAdaptive(light: DesignPrimitive.paper100, dark: DesignPrimitive.ink750)
    /// Carte, menu, fenêtre qui se détache du fond ; pas comme fond de page.
    public static let surfaceRaised: Color = makeAdaptive(light: DesignPrimitive.paper0, dark: DesignPrimitive.ink700)
    /// Texte principal et icône porteuse de sens ; pas sur un aplat d'accent (on-accent).
    public static let text: Color = makeAdaptive(light: DesignPrimitive.ink800, dark: DesignPrimitive.paper50)
    /// Texte d'appoint, légende, icône discrète ; jamais une information indispensable seule.
    public static let textMuted: Color = makeAdaptive(light: DesignPrimitive.ink500, dark: DesignPrimitive.ink300, lightHigh: DesignPrimitive.ink600, darkHigh: DesignPrimitive.ink200)
    /// Filet de séparation, contour discret ; décoratif, sans seuil de contraste. Pas pour le contour d'un champ qui doit se voir seul.
    public static let rule: Color = makeAdaptive(light: DesignPrimitive.paper100, dark: DesignPrimitive.ink700, lightHigh: DesignPrimitive.ink400, darkHigh: DesignPrimitive.ink400)
    /// Filet au survol ; pas au repos.
    public static let ruleHover: Color = makeAdaptive(light: DesignPrimitive.paper200, dark: DesignPrimitive.ink600, lightHigh: DesignPrimitive.ink500, darkHigh: DesignPrimitive.ink300)
    /// Fond d'une ligne ou d'un contrôle au survol ; pas pour la sélection.
    public static let hover: Color = makeAdaptive(light: DesignPrimitive.paper50, dark: DesignPrimitive.ink700)
    /// Fond d'un élément sélectionné, accent très léger ; pas pour le survol.
    public static func selection(_ variant: DesignPalette) -> Color {
        makeAdaptive(light: DesignPrimitive.accent500(variant), dark: DesignPrimitive.accent200(variant), lightOpacity: 0.12, darkOpacity: 0.24)
    }
    /// La seule couleur d'accent : action principale, sélection, repère. Pas pour décorer.
    public static func accent(_ variant: DesignPalette) -> Color {
        makeAdaptive(light: DesignPrimitive.accent500(variant), dark: DesignPrimitive.accent200(variant))
    }
    /// L'accent quand il est un texte ou une petite icône (lien) : la nuance de l'accent qui atteint 4,5:1 sur le fond.
    public static func accentText(_ variant: DesignPalette) -> Color {
        makeAdaptive(light: DesignPrimitive.accentInk600(variant), dark: DesignPrimitive.accent200(variant))
    }
    /// Texte et icône posés sur un aplat d'accent ; jamais ailleurs.
    public static let onAccent: Color = makeAdaptive(light: DesignPrimitive.paper0, dark: DesignPrimitive.ink800)
    /// L'anneau de focus au clavier : 3:1 au moins sur le fond ; jamais retiré.
    public static func focus(_ variant: DesignPalette) -> Color {
        makeAdaptive(light: DesignPrimitive.accent500(variant), dark: DesignPrimitive.accent200(variant))
    }
    /// L'erreur et la suppression, en texte, icône ou aplat ; jamais une décoration.
    public static let danger: Color = makeAdaptive(light: DesignPrimitive.red500, dark: DesignPrimitive.red300, lightHigh: DesignPrimitive.red600, darkHigh: DesignPrimitive.red150)
    /// Texte posé sur un aplat danger.
    public static let onDanger: Color = makeAdaptive(light: DesignPrimitive.paper0, dark: DesignPrimitive.ink800)
    /// La réussite confirmée, en texte, icône ou aplat ; jamais une décoration.
    public static let success: Color = makeAdaptive(light: DesignPrimitive.green600, dark: DesignPrimitive.green300, lightHigh: DesignPrimitive.green650, darkHigh: DesignPrimitive.green200)
    /// Texte posé sur un aplat success.
    public static let onSuccess: Color = makeAdaptive(light: DesignPrimitive.paper0, dark: DesignPrimitive.ink800)
    /// L'avertissement, en texte, icône ou aplat ; jamais une décoration.
    public static let warning: Color = makeAdaptive(light: DesignPrimitive.amber500, dark: DesignPrimitive.amber300, lightHigh: DesignPrimitive.amber600, darkHigh: DesignPrimitive.amber200)
    /// Texte posé sur un aplat warning.
    public static let onWarning: Color = makeAdaptive(light: DesignPrimitive.paper0, dark: DesignPrimitive.ink800)
    /// L'information neutre, en texte, icône ou aplat ; pas l'accent de la marque.
    public static let info: Color = makeAdaptive(light: DesignPrimitive.blue500, dark: DesignPrimitive.blue300, lightHigh: DesignPrimitive.blue600, darkHigh: DesignPrimitive.blue200)
    /// Texte posé sur un aplat info.
    public static let onInfo: Color = makeAdaptive(light: DesignPrimitive.paper0, dark: DesignPrimitive.ink800)
    /// Ombre proche : nette et plus dense, elle pose l'objet ; lue par les élévations seulement.
    public static let shadowNear: Color = makeAdaptive(light: DesignPrimitive.ink900, dark: DesignPrimitive.ink900, lightOpacity: 0.12, darkOpacity: 0.5)
    /// Ombre lointaine : diffuse et légère, elle dit la hauteur ; lue par les élévations seulement.
    public static let shadowFar: Color = makeAdaptive(light: DesignPrimitive.ink900, dark: DesignPrimitive.ink900, lightOpacity: 0.08, darkOpacity: 0.4)
    /// Voile derrière une fenêtre modale ; pas derrière un panneau parallèle.
    public static let scrim: Color = makeAdaptive(light: DesignPrimitive.ink900, dark: DesignPrimitive.ink900, lightOpacity: 0.32, darkOpacity: 0.56)
    /// L'accent d'un contrôle natif (interrupteur, case) dont le libellé est blanc : toujours la nuance claire, même en sombre. Pas pour du texte.
    public static func accentControl(_ variant: DesignPalette) -> Color {
        makeColor(DesignPrimitive.accent500(variant))
    }
    /// La teinte du verre du bandeau ; l'opacité se règle à l'usage. Pas pour un aplat d'interface.
    public static func glassTint(_ variant: DesignPalette) -> Color {
        makeColor(DesignPrimitive.glass500(variant))
    }
    /// La nuance 1 de l'aperçu d'une palette dans le sélecteur ; pas pour l'interface.
    public static func palettePreview1(_ variant: DesignPalette) -> Color {
        makeColor(DesignPrimitive.palettePreview700(variant))
    }
    /// La nuance 2 de l'aperçu d'une palette dans le sélecteur ; pas pour l'interface.
    public static func palettePreview2(_ variant: DesignPalette) -> Color {
        makeColor(DesignPrimitive.palettePreview500(variant))
    }
    /// La nuance 3 de l'aperçu d'une palette dans le sélecteur ; pas pour l'interface.
    public static func palettePreview3(_ variant: DesignPalette) -> Color {
        makeColor(DesignPrimitive.palettePreview300(variant))
    }
    /// La nuance 4 de l'aperçu d'une palette dans le sélecteur ; pas pour l'interface.
    public static func palettePreview4(_ variant: DesignPalette) -> Color {
        makeColor(DesignPrimitive.palettePreview100(variant))
    }

    /// The color of a 0xRRGGBB sRGB value, the same in light and dark.
    static func makeColor(_ value: UInt32) -> Color {
        Color(.sRGB, red: makeChannel(value, 16), green: makeChannel(value, 8), blue: makeChannel(value, 0))
    }

    /// A color that follows the light or dark appearance, and the system's increased contrast when a high value is given.
    static func makeAdaptive(light: UInt32, dark: UInt32, lightHigh: UInt32? = nil, darkHigh: UInt32? = nil, lightOpacity: Double = 1, darkOpacity: Double = 1) -> Color {
        #if canImport(AppKit)
        Color(nsColor: NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua])
            let isDark = match == .darkAqua || match == .accessibilityHighContrastDarkAqua
            let isHigh = match == .accessibilityHighContrastAqua || match == .accessibilityHighContrastDarkAqua
            let value = isDark ? (isHigh ? darkHigh ?? dark : dark) : (isHigh ? lightHigh ?? light : light)
            return makePlatformColor(value, opacity: isDark ? darkOpacity : lightOpacity)
        })
        #else
        Color(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let isHigh = traits.accessibilityContrast == .high
            let value = isDark ? (isHigh ? darkHigh ?? dark : dark) : (isHigh ? lightHigh ?? light : light)
            return makePlatformColor(value, opacity: isDark ? darkOpacity : lightOpacity)
        })
        #endif
    }

    #if canImport(AppKit)
    private static func makePlatformColor(_ value: UInt32, opacity: Double) -> NSColor {
        NSColor(srgbRed: makeChannel(value, 16), green: makeChannel(value, 8), blue: makeChannel(value, 0), alpha: opacity)
    }
    #else
    private static func makePlatformColor(_ value: UInt32, opacity: Double) -> UIColor {
        UIColor(red: makeChannel(value, 16), green: makeChannel(value, 8), blue: makeChannel(value, 0), alpha: opacity)
    }
    #endif

    private static func makeChannel(_ value: UInt32, _ shift: UInt32) -> Double {
        Double((value >> shift) & 0xFF) / 255
    }
}
