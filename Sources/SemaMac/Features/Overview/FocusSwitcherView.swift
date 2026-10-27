// Permet de parcourir visuellement les repères en cache sans changer le graphique avant validation.
import SwiftUI
import MarketCore

struct FocusSwitcherView: View {
    private static let panelMaxWidth: CGFloat = 700
    private static let panelInset: CGFloat = 40
    private static let panelSpacing: CGFloat = 12
    private static let tilesPadding: CGFloat = 12
    private static let strokeOpacity = 0.08
    private static let contrastStrokeOpacity = 0.6
    private static let selectedStrokeOpacity = 0.6
    private static let tileWidth: CGFloat = 166
    private static let tilePadding: CGFloat = 16
    private static let tileSpacing: CGFloat = 14
    private static let nameLines = 2
    private static let nameHeight: CGFloat = 32
    private static let valueTracking: CGFloat = -0.6
    private static let valueMinimumScale: CGFloat = 0.75
    private static let valueFont = Font.system(size: 24)
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let selection: String
    let choose: (MarketSeries) -> Void

    var body: some View {
        VStack(spacing: Self.panelSpacing) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: Theme.minorSpacing) {
                        ForEach(store.followedSeries) { item in
                            tile(item).id(item.id)
                        }
                    }.padding(Self.tilesPadding)
                }
                .scrollIndicators(.hidden)
                .onAppear { proxy.scrollTo(selection, anchor: .center) }
                .onChange(of: selection) { _, id in
                    withAnimation(reduceMotion ? nil : FocusSwitcherMotion.selection) { proxy.scrollTo(id, anchor: .center) }
                }
            }
        }
        .frame(maxWidth: Self.panelMaxWidth)
        .background {
            let shape = RoundedRectangle(cornerRadius: Theme.surfaceCorner, style: .continuous)
            if reduceTransparency || contrast == .increased { shape.fill(Theme.surface) }
            else { shape.fill(.regularMaterial) }
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.surfaceCorner, style: .continuous)
                .strokeBorder(Color.primary.opacity(contrast == .increased ? Self.contrastStrokeOpacity : Self.strokeOpacity), lineWidth: Theme.hairline)
                .allowsHitTesting(false)
        }
        .shadow(.switcher)
        .padding(.horizontal, Self.panelInset)
        .accessibilityElement(children: .contain).accessibilityLabel("Choisir un repère")
    }

    private func tile(_ item: MarketSeries) -> some View {
        let displayed = store.displayedSeries(item)
        let selected = item.id == selection
        return Button { choose(item) } label: {
            VStack(alignment: .leading, spacing: Self.tileSpacing) {
                Text(MarketFormat.name(displayed)).font(.callout.weight(.medium))
                    .lineLimit(Self.nameLines).multilineTextAlignment(.leading).frame(height: Self.nameHeight, alignment: .topLeading)
                Text(MarketFormat.value(displayed)).font(Self.valueFont)
                    .tracking(Self.valueTracking).monospacedDigit().lineLimit(1).minimumScaleFactor(Self.valueMinimumScale)
                Text(MarketFormat.change(displayed, period: store.period))
                    .font(.subheadline).monospacedDigit().foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary).frame(width: Self.tileWidth, alignment: .leading).padding(Self.tilePadding)
            .background(selected ? store.palette.accent.opacity(Theme.selectionOpacity) : .clear,
                in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                        .strokeBorder(store.palette.accent.opacity(Self.selectedStrokeOpacity), lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.cardCorner))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(MarketFormat.name(displayed)), \(MarketFormat.value(displayed))\()")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
