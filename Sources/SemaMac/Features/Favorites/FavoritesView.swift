// Rubrique Favoris : grille des repères épinglés.
import SwiftUI
import MarketCore

private struct IndicatorTile: View {
    private static let compactValueFont = Font.system(size: 24)
    private static let compactSpacing: CGFloat = 14
    private static let spacing: CGFloat = 10
    private static let titleSpacing: CGFloat = 6
    private static let singleActionInset: CGFloat = 22
    private static let doubleActionInset: CGFloat = 48
    private static let valueTracking: CGFloat = -0.6
    private static let valueMinimumScale: CGFloat = 0.85
    private static let valueSpacing: CGFloat = 6
    private static let compactPadding: CGFloat = 16
    private static let padding: CGFloat = 14
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
                        Text(displayed.name).font(.body.weight(.medium)).lineLimit(1)
                        if series.isDemo { Text("Démo").font(.subheadline).foregroundStyle(.secondary) }
                        if !store.isSourceEnabled(for: series.id) { Image(systemName: "pause.circle").foregroundStyle(.secondary).help("Source désactivée · historique conservé") }
                    }
                    .padding(.trailing, series.exchangeRatePair == nil ? Self.singleActionInset : Self.doubleActionInset)
                    HStack(alignment: .firstTextBaseline) {
                        Text(MarketFormat.value(displayed))
                            .font(compact ? Self.compactValueFont : .title)
                            .tracking(Self.valueTracking).monospacedDigit().lineLimit(1).minimumScaleFactor(Self.valueMinimumScale)
                        Spacer(minLength: Self.valueSpacing)
                        Text(MarketFormat.change(displayed, period: .month))
                            .font(.subheadline).monospacedDigit().foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(.primary)
                .padding(compact ? Self.compactPadding : Self.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(fill, in: RoundedRectangle(cornerRadius: SemaTheme.rowCorner, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: SemaTheme.rowCorner, style: .continuous))
            }
            .buttonStyle(SemaPressStyle())
            .accessibilityLabel("\(displayed.name), \(MarketFormat.value(displayed))\(series.isDemo ? ", démonstration" : "")")
            .accessibilityValue(selected ? "Sélectionné" : "")
            HStack(spacing: 0) {
                ExchangeDirectionButton(series: series)
                FavoriteButton(seriesID: series.id, seriesName: displayed.name)
            }.padding(SemaTheme.minorSpacing)
        }
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: SemaTheme.hoverDuration), value: isHovered)
    }

    private var fill: Color {
        if selected { return accent.opacity(SemaTheme.selectionOpacity) }
        if isHovered { return SemaTheme.hoverFill }
        return compact ? SemaTheme.surface : .clear
    }
}

struct FavoritesView: View {
    private static let emptyMinHeight: CGFloat = 380
    private static let tileMinWidth: CGFloat = 250
    private static let gridSpacing: CGFloat = 16
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
