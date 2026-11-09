// Réglages visuels de l’app transmis aux surfaces flottantes : accent, verre, apparence et langue.
import SwiftUI

struct RibbonEnvironment: ViewModifier {
    let store: AppStore

    func body(content: Content) -> some View {
        content
            .environment(store)
            .environment(\.semaAccent, store.palette.accent).tint(store.palette.controlAccent)
            .environment(\.semaGlassTint, store.palette.glassTint)
            .environment(\.semaGlassSettings, store.ribbonGlass)
            .preferredColorScheme(store.appearance.colorScheme)
            .environment(\.locale, .french)
    }
}
