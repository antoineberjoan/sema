// Réglages visuels de l’app transmis aux surfaces flottantes : accent, verre, apparence et langue.
import SemaDesign
import SwiftUI

struct RibbonEnvironment: ViewModifier {
    let store: AppStore

    func body(content: Content) -> some View {
        content
            .environment(store)
            .environment(\.palette, store.palette).tint(DesignColor.accentControl(store.palette))
            .environment(\.glassSettings, store.ribbonGlass)
            .preferredColorScheme(store.appearance.colorScheme)
            .environment(\.locale, .french)
    }
}
