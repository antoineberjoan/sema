import SwiftUI
import MarketCore

struct OverviewView: View {
    @Environment(AppStore.self) private var store
    private var items: [MarketSeries] { store.macroSeries.filter { $0.category == store.category } }

    var body: some View {
        @Bindable var store = store
        HStack(alignment: .top, spacing: 26) {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Famille de repères", selection: $store.category) {
                    Text("Marchés").tag(SeriesCategory.markets)
                    Text("Épargne & économie").tag(SeriesCategory.savings)
                }
                .pickerStyle(.segmented).labelsHidden()
                LazyVStack(spacing: 4) {
                    ForEach(items) { item in
                        IndicatorTile(series: item, selected: store.selectedSeriesID == item.id) { store.show(item) }
                    }
                }
            }
            .frame(width: 285)
            SeriesDetailView(series: store.selectedSeries).frame(minWidth: 360, maxWidth: .infinity)
        }
        .onChange(of: store.category) { _, category in
            if store.selectedSeries.category != category, let first = items.first { store.selectedSeriesID = first.id }
        }
    }
}

struct IndicatorTile: View {
    @Environment(\.semaAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    let series: MarketSeries
    var selected = false
    var compact = false
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: compact ? 14 : 10) {
                    HStack(spacing: 6) {
                        Text(series.name).font(.system(size: 13, weight: .medium)).lineLimit(1)
                        if series.isDemo { Text("Démo").font(.system(size: 11)).foregroundStyle(.secondary) }
                    }
                    .padding(.trailing, 22)
                    HStack(alignment: .firstTextBaseline) {
                        Text(MarketFormat.value(series))
                            .font(.system(size: compact ? 24 : 22, weight: .regular))
                            .tracking(-0.6).monospacedDigit().lineLimit(1).minimumScaleFactor(0.85)
                        Spacer(minLength: 6)
                        Text(MarketFormat.change(series, period: .month))
                            .font(.system(size: 11)).monospacedDigit().foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(.primary)
                .padding(compact ? 16 : 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(SemaPressStyle())
            .accessibilityLabel("\(series.name), \(MarketFormat.value(series))\(series.isDemo ? ", démonstration" : "")")
            .accessibilityValue(selected ? "Sélectionné" : "")
            FavoriteButton(seriesID: series.id).padding(8)
        }
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: isHovered)
    }

    private var fill: Color {
        if selected { return accent.opacity(0.10) }
        if isHovered { return Color.primary.opacity(0.04) }
        return compact ? SemaTheme.surface : .clear
    }
}

struct FavoriteButton: View {
    @Environment(AppStore.self) private var store
    @Environment(\.semaAccent) private var accent
    let seriesID: String
    var body: some View {
        Button { store.toggleFavorite(seriesID) } label: {
            Image(systemName: store.isFavorite(seriesID) ? "star.fill" : "star")
                .font(.system(size: 12)).foregroundStyle(store.isFavorite(seriesID) ? accent : Color.secondary)
                .frame(width: 26, height: 26).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(store.isFavorite(seriesID) ? "Retirer des favoris" : "Ajouter aux favoris")
        .accessibilityLabel(store.isFavorite(seriesID) ? "Retirer \(seriesID) des favoris" : "Ajouter \(seriesID) aux favoris")
    }
}

struct SeriesDetailView: View {
    @Environment(AppStore.self) private var store
    let series: MarketSeries

    var body: some View {
        @Bindable var store = store
        Surface {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(series.name).font(.system(size: 18, weight: .semibold))
                        Text(series.subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    OriginBadge(series: series)
                }
                VStack(alignment: .leading, spacing: 9) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(series.latest.map { MarketFormat.number($0.value, digits: series.fractionDigits) } ?? "—")
                            .font(.system(size: 44, weight: .medium)).tracking(-1.4).monospacedDigit()
                            .lineLimit(1).minimumScaleFactor(0.8)
                        Text(series.unit.symbol).font(.system(size: 18)).foregroundStyle(.secondary)
                    }
                    Text(MarketFormat.change(series, period: store.period) + " sur " + store.period.title)
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Picker("Période de l’historique", selection: $store.period) {
                    ForEach(HistoryPeriod.allCases.filter { series.supports($0) }) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented).labelsHidden()
                HistoryChart(series: series, period: store.period, height: 245)
                HStack(alignment: .firstTextBaseline) {
                    Label(observationLabel, systemImage: "calendar")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Button { store.isAlertSheetPresented = true } label: {
                        Label("Créer une alerte", systemImage: "bell.badge")
                    }
                    .buttonStyle(.borderless).font(.system(size: 12))
                }
                DisclosureGroup("Source et publication") {
                    VStack(alignment: .leading, spacing: 8) {
                        if series.isDemo {
                            Text("Valeurs fictives pour explorer l’application.")
                        } else {
                            Text(series.frequency == .monthly ? "Publication mensuelle · période de référence indiquée ci-dessus."
                                 : "Publication quotidienne · dernière observation disponible.")
                            if let updatedAt = series.latest?.updatedAt {
                                Text("Mise à jour source : " + MarketFormat.date(updatedAt))
                            }
                            if let url = series.sourceURL { Link(series.source, destination: url) }
                        }
                    }
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                }
                .font(.system(size: 11)).foregroundStyle(.secondary)
                if let status = series.latest?.status, status != "A" {
                    Text("Statut de la source : \(status) · consultez le détail officiel.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: series, initial: true) { _, item in
            if !item.supports(store.period) {
                store.period = HistoryPeriod.allCases.last(where: { item.supports($0) }) ?? .month
            }
        }
    }

    private var observationLabel: String {
        guard series.frequency == .monthly, let latest = series.latest else {
            return "Observation du " + MarketFormat.date(series.latest?.date)
        }
        var format = Date.FormatStyle().month(.wide).year().locale(Locale(identifier: "fr_FR"))
        format.timeZone = TimeZone(secondsFromGMT: 0)!
        return "Période : " + latest.date.formatted(format)
    }
}

struct FavoritesView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        if store.favorites.isEmpty {
            ContentUnavailableView("Votre veille commence ici", systemImage: "star",
                                   description: Text("Ajoutez des indicateurs avec l’étoile pour les retrouver ici."))
                .frame(maxWidth: .infinity, minHeight: 380)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 16)], spacing: 16) {
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
