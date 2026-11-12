// Permet de parcourir visuellement les repères en cache sans changer le graphique avant validation.
import SemaDesign
import SwiftUI
import MarketCore

struct FocusSwitcherView: View {
    private static let panelMaxWidth: CGFloat = 700
    private static let panelInset = DesignSpace.pageInsetWide
    private static let tilesPadding = DesignSpace.menuInset
    private static let tileWidth: CGFloat = 166
    private static let tilePadding = DesignSpace.cardInset
    private static let tileSpacing = DesignSpace.titleGap
    private static let tilesSpacing = DesignSpace.itemGap
    private static let nameLines = 2
    private static let nameHeight: CGFloat = 32
    private static let valueMinimumScale: CGFloat = 0.75
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let selection: String
    let choose: (MarketSeries) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: Self.tilesSpacing) {
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
        .frame(maxWidth: Self.panelMaxWidth)
        .background {
            let shape = RoundedRectangle(cornerRadius: DesignRadius.window, style: .continuous)
            if reduceTransparency || contrast == .increased { shape.fill(DesignColor.surfaceRaised) }
            else { shape.fill(.regularMaterial) }
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignRadius.window, style: .continuous)
                .strokeBorder(DesignColor.rule, lineWidth: DesignBorder.width)
                .allowsHitTesting(false)
        }
        .elevation(DesignElevation.window)
        .padding(.horizontal, Self.panelInset)
        .accessibilityElement(children: .contain).accessibilityLabel("Choisir un repère")
    }

    private func tile(_ item: MarketSeries) -> some View {
        let displayed = store.displayedSeries(item)
        let isSelected = item.id == selection
        return Button { choose(item) } label: {
            VStack(alignment: .leading, spacing: Self.tileSpacing) {
                Text(MarketFormat.name(displayed)).typeRole(.label)
                    .lineLimit(Self.nameLines).multilineTextAlignment(.leading).frame(height: Self.nameHeight, alignment: .topLeading)
                Text(MarketFormat.value(displayed)).typeRole(.figure)
                    .lineLimit(1).minimumScaleFactor(Self.valueMinimumScale)
                // Surface translucide : le texte secondaire garde le style système (décision surfaces-translucides).
                Text(MarketFormat.change(displayed, period: store.period(for: item)))
                    .typeRole(.caption).monospacedDigit().foregroundStyle(.secondary)
            }
            .foregroundStyle(DesignColor.text).frame(width: Self.tileWidth, alignment: .leading).padding(Self.tilePadding)
            .background(isSelected ? DesignColor.selection(store.palette) : .clear,
                in: RoundedRectangle(cornerRadius: DesignRadius.block, style: .continuous))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: DesignRadius.block, style: .continuous)
                        .strokeBorder(DesignColor.accent(store.palette), lineWidth: DesignBorder.width)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: DesignRadius.block))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(MarketFormat.name(displayed)), \(MarketFormat.value(displayed))")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
