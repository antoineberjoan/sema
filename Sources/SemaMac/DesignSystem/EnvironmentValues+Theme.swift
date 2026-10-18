// Transmet l’accent, la teinte du verre et ses réglages aux vues par l’environnement.
import SwiftUI
import MarketCore

private struct AccentKey: EnvironmentKey {
    static let defaultValue: Color = SemaPalette.graphite.accent
}

private struct GlassTintKey: EnvironmentKey {
    static let defaultValue: Color = .clear
}

private struct GlassSettingsKey: EnvironmentKey {
    static let defaultValue = RibbonGlassPreferences.standard
}

extension EnvironmentValues {
    var semaGlassSettings: RibbonGlassPreferences {
        get { self[GlassSettingsKey.self] }
        set { self[GlassSettingsKey.self] = newValue }
    }
    var semaGlassTint: Color {
        get { self[GlassTintKey.self] }
        set { self[GlassTintKey.self] = newValue }
    }
    var semaAccent: Color {
        get { self[AccentKey.self] }
        set { self[AccentKey.self] = newValue }
    }
}
