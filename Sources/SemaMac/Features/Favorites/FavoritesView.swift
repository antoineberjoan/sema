// Rubrique Favoris : grille des repères épinglés.
import SwiftUI
import MarketCore

private struct IndicatorTile: View {
    private static let compactSpacing = Spacing.s16
    private static let spacing = Spacing.s10
    private static let titleSpacing = Spacing.s6
    private static let singleActionInset = Spacing.s24
    private static let doubleActionInset = Spacing.s48
    private static let valueMinimumScale: CGFloat = 0.85
    private static let valueSpacing = Spacing.s6
    private static let compactPadding = Spacing.s16
    private static let padding = Spacing.s16
    @Environment(AppStore.self) private var store
    @Environment(\.semaAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    let series: MarketSeries
    var selected = false
    var compact = false
    let action: () -> Void

    var body: some View {
        let displayed = store.displayedSeries(series)
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: compact ? Self.compactSpacing : Self.spacing) {
                    HStack(spacing: Self.titleSpacing) {
                        Text(MarketFormat.name(displayed)).typeRole(.heading).lineLimit(1)
                        if !store.isSourceEnabled(for: series.id) { Image(systemName: "pause.circle").foregroundStyle(.secondary).help("Source désactivée · historique conservé") }
                    }
                    .padding(.trailing, series.exchangeRatePair == nil ? Self.singleActionInset : Self.doubleActionInset)
                    HStack(alignment: .firstTextBaseline) {
                        Text(MarketFormat.value(displayed))
                            .typeRole(.figure)
                            .lineLimit(1).minimumScaleFactor(Self.valueMinimumScale)
                        Spacer(minLength: Self.valueSpacing)
                        Text(MarketFormat.change(displayed, period: .month))
                            .typeRole(.caption).monospacedDigit().foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(.primary)
                .padding(compact ? Self.compactPadding : Self.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(fill, in: RoundedRectangle(cornerRadius: Theme.rowCorner, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: Theme.rowCorner, style: .continuous))
            }
            .buttonStyle(PressStyle())
            .accessibilityLabel("\(MarketFormat.name(displayed)), \(MarketFormat.value(displayed))")
            .accessibilityValue(selected ? "Sélectionné" : "")
            HStack(spacing: 0) {
                ExchangeDirectionButton(series: series)
                FavoriteButton(seriesID: series.id, seriesName: MarketFormat.name(displayed))
            }.padding(Theme.minorSpacing)
        }
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeInOut(duration: Theme.hoverDuration), value: isHovered)
    }

    private var fill: Color {
        if selected { return accent.opacity(Theme.selectionOpacity) }
        if isHovered { return Theme.hoverFill }
        return compact ? Theme.surface : .clear
    }
}

struct FavoritesView: View {
    private static let emptyMinHeight: CGFloat = 380
    private static let tileMinWidth: CGFloat = 250
    private static let gridSpacing = Spacing.s16
    @Environment(AppStore.self) private var store
    var body: some View {
        if store.favorites.isEmpty {
            ContentUnavailableView("Votre veille commence ici", systemImage: "star",
                                   description: Text("Ajoutez des indicateurs avec l’étoile pour les retrouver ici."))
                .frame(maxWidth: .infinity, minHeight: Self.emptyMinHeight)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: Self.tileMinWidth), spacing: Self.gridSpacing)], spacing: Self.gridSpacing) {
                ForEach(store.favorites) { series in
                    IndicatorTile(series: series, compact: true) {
                        store.show(series)
                        store.section = .overview
                    }
                }
            }
        }
    }
}
