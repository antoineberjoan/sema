// Transmet la palette choisie et les réglages du verre aux vues par l’environnement.
import MarketCore
import SemaDesign
import SwiftUI

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = DesignPalette.brand
}

private struct GlassSettingsKey: EnvironmentKey {
    static let defaultValue = RibbonGlassPreferences.standard
}

extension EnvironmentValues {
    var glassSettings: RibbonGlassPreferences {
        get { self[GlassSettingsKey.self] }
        set { self[GlassSettingsKey.self] = newValue }
    }
    var palette: DesignPalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
