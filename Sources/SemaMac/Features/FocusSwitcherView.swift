// Permet de parcourir visuellement les repères en cache sans changer le graphique avant validation.
import SwiftUI
import MarketCore

// SÉLECTEUR
//   0 ms  ⌘ + flèche révèle les repères, le prochain est mis en évidence.
// 180 ms  Le défilement centre la sélection avec un ressort sans rebond.
// Relâcher ⌘ / Entrée → ouverture ; Échap / sortie de fenêtre → annulation.
enum FocusSwitcherMotion {
    static let selection = Animation.snappy(duration: 0.18, extraBounce: 0)
    static let presentation = Animation.snappy(duration: 0.20, extraBounce: 0)
}

struct FocusSwitcherView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let selection: String
    let choose: (MarketSeries) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(store.followedSeries) { item in
                            tile(item).id(item.id)
                        }
                    }.padding(12)
                }
                .scrollIndicators(.hidden)
                .onAppear { proxy.scrollTo(selection, anchor: .center) }
                .onChange(of: selection) { _, id in
                    withAnimation(reduceMotion ? nil : FocusSwitcherMotion.selection) { proxy.scrollTo(id, anchor: .center) }
                }
            }
            Text("↑ ↓  ·  relâchez ⌘ pour ouvrir")
                .font(.system(size: 11)).foregroundStyle(.secondary).padding(.bottom, 14)
        }
        .frame(maxWidth: 700)
        .background {
            let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
            if reduceTransparency || contrast == .increased { shape.fill(SemaTheme.surface) }
            else { shape.fill(.regularMaterial) }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(contrast == .increased ? 0.6 : 0.08), lineWidth: 0.5)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.18), radius: 28, y: 12)
        .padding(.horizontal, 40)
        .accessibilityElement(children: .contain).accessibilityLabel("Choisir un repère")
    }

    private func tile(_ item: MarketSeries) -> some View {
        let displayed = store.displayedSeries(item)
        let selected = item.id == selection
        return Button { choose(item) } label: {
            VStack(alignment: .leading, spacing: 14) {
                Text(displayed.name).font(.system(size: 12, weight: .medium))
                    .lineLimit(2).multilineTextAlignment(.leading).frame(height: 32, alignment: .topLeading)
                Text(MarketFormat.value(displayed)).font(.system(size: 24, weight: .regular))
                    .tracking(-0.6).monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
                Text(MarketFormat.change(displayed, period: store.period))
                    .font(.system(size: 11)).monospacedDigit().foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary).frame(width: 166, alignment: .leading).padding(16)
            .background(selected ? store.palette.accent.opacity(0.14) : .clear,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(store.palette.accent.opacity(0.6), lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(displayed.name), \(MarketFormat.value(displayed))\(item.isDemo ? ", données fictives" : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
