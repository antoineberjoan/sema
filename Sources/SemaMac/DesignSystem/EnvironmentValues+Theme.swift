// Transmet l’accent, la teinte du verre et ses réglages aux vues par l’environnement.
import SwiftUI
import MarketCore

private struct SemaAccentKey: EnvironmentKey {
    static let defaultValue: Color = SemaPalette.graphite.accent
}

private struct SemaGlassTintKey: EnvironmentKey {
    static let defaultValue: Color = .clear
}

private struct SemaGlassSettingsKey: EnvironmentKey {
    static let defaultValue = RibbonGlassPreferences.standard
}

extension EnvironmentValues {
    var semaGlassSettings: RibbonGlassPreferences {
        get { self[SemaGlassSettingsKey.self] }
        set { self[SemaGlassSettingsKey.self] = newValue }
    }
    var semaGlassTint: Color {
        get { self[SemaGlassTintKey.self] }
        set { self[SemaGlassTintKey.self] = newValue }
    }
    var semaAccent: Color {
        get { self[SemaAccentKey.self] }
        set { self[SemaAccentKey.self] = newValue }
    }
}
