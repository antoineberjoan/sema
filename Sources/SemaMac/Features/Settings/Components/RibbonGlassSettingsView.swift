// Règle le verre du bandeau avec l’aperçu d’un favori et une remise à zéro limitée.
import SemaDesign
import SwiftUI
import MarketCore

struct RibbonGlassSettingsView: View {
    private static let sliderSpacing = DesignSpace.itemGap
    private static let labelWidth: CGFloat = 136
    private static let valueWidth: CGFloat = 38
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    private var opaque: Bool { reduceTransparency || contrast == .increased }

    var body: some View {
        Section("Verre des cartes") {
            if let series = store.favorites.first {
                RibbonCard(series: store.displayedSeries(series), period: .year, action: {})
                    .frame(height: MenuRibbonLayout.cardHeight)
                    .allowsHitTesting(false).accessibilityHidden(true)
                    .environment(\.palette, store.palette)
                    .environment(\.glassSettings, store.ribbonGlass)
            }

            glassSlider("Transparence", symbol: "drop", value: Binding(get: { store.ribbonGlass.transparency }, set: { value in
                store.setRibbonGlass(RibbonGlassPreferences(transparency: value, tint: store.ribbonGlass.tint,
                                                            grain: store.ribbonGlass.grain))
            }))
            .disabled(opaque)

            glassSlider("Teinte", symbol: "circle.lefthalf.filled", value: Binding(get: { store.ribbonGlass.tint }, set: { value in
                store.setRibbonGlass(RibbonGlassPreferences(transparency: store.ribbonGlass.transparency,
                                                            tint: value, grain: store.ribbonGlass.grain))
            }))
            .disabled(opaque || store.palette == .graphite)

            glassSlider("Grain", symbol: "aqi.medium", value: Binding(get: { store.ribbonGlass.grain }, set: { value in
                store.setRibbonGlass(RibbonGlassPreferences(transparency: store.ribbonGlass.transparency,
                                                            tint: store.ribbonGlass.tint, grain: value))
            }))
            .disabled(opaque)

            Text(explanation).typeRole(.small).foregroundStyle(DesignColor.textMuted)
            Button("Réinitialiser le verre") { store.setRibbonGlass(.standard) }
                .disabled(store.ribbonGlass == .standard)
        }
    }

    private var explanation: String {
        if opaque {
            return "macOS impose une surface opaque avec Réduire la transparence ou Augmenter le contraste. Vos réglages sont conservés."
        }
        return "Le flou reste natif macOS. La transparence règle le voile des cartes du bandeau."
            + (store.palette == .graphite ? " Graphite reste neutre ; choisissez une palette colorée pour ajuster la teinte." : " La teinte reprend votre palette.")
    }

    private func glassSlider(_ title: String, symbol: String, value: Binding<Double>) -> some View {
        HStack(spacing: Self.sliderSpacing) {
            Label(title, systemImage: symbol).frame(width: Self.labelWidth, alignment: .leading)
            Slider(value: value, in: 0...1)
                .accessibilityLabel(title)
                .accessibilityValue("\(Int((value.wrappedValue * 100).rounded())) %")
            Text(value.wrappedValue, format: .percent.precision(.fractionLength(0)))
                .typeRole(.caption).monospacedDigit().foregroundStyle(DesignColor.textMuted)
                .frame(width: Self.valueWidth, alignment: .trailing).accessibilityHidden(true)
        }
    }
}
