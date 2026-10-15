import SwiftUI
import MarketCore

struct OverviewView: View {
    @Environment(AppStore.self) private var store
    private var items: [MarketSeries] { store.macroSeries.filter { $0.category == store.category } }

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 23) {
            Picker("Famille de repères", selection: $store.category) {
                Text("Marchés & devises").tag(SeriesCategory.markets)
                Text("Épargne & économie").tag(SeriesCategory.savings)
            }
            .pickerStyle(.segmented).labelsHidden().frame(width: 350)

            HStack(alignment: .top, spacing: 23) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(items) { item in
                        IndicatorTile(series: item, selected: store.selectedSeriesID == item.id) { store.show(item) }
                    }
                }
                .frame(width: 350)
                SeriesDetailView(series: store.selectedSeries).frame(maxWidth: .infinity)
            }
        }
        .onChange(of: store.category) { _, category in
            if store.selectedSeries.category != category, let first = items.first { store.selectedSeriesID = first.id }
        }
    }
}

struct IndicatorTile: View {
    @Environment(AppStore.self) private var store
    let series: MarketSeries
    var selected = false
    var compact = false
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: compact ? 9 : 13) {
                    Text(series.name).font(.system(size: 12)).foregroundStyle(.secondary).padding(.trailing, 17)
                    Text(MarketFormat.value(series)).font(.system(size: compact ? 25 : 28, weight: .medium))
                        .tracking(-0.9).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
                    HStack(alignment: .bottom) {
                        Text(MarketFormat.change(series, period: .month)).font(.system(size: 11)).foregroundStyle(.secondary)
                        Spacer(minLength: 3)
                        OriginBadge(series: series)
                    }
                    if !compact {
                        HStack { Text("sur 1 mois").font(.system(size: 10)).foregroundStyle(.secondary); Spacer(); Sparkline(series: series) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(compact ? 14 : 17)
                .background(selected ? SemaTheme.accent.opacity(0.09) : SemaTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selected ? SemaTheme.accent.opacity(0.35) : SemaTheme.separator, lineWidth: 0.7))
                .contentShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(series.name), \(MarketFormat.value(series))\(series.isDemo ? ", démonstration" : "")")
            FavoriteButton(seriesID: series.id).padding(10)
        }
    }
}

struct FavoriteButton: View {
    @Environment(AppStore.self) private var store
    let seriesID: String
    var body: some View {
        Button { store.toggleFavorite(seriesID) } label: {
            Image(systemName: store.isFavorite(seriesID) ? "star.fill" : "star")
                .font(.system(size: 11)).foregroundStyle(store.isFavorite(seriesID) ? SemaTheme.accent : Color.secondary.opacity(0.7))
                .frame(width: 22, height: 22).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(store.isFavorite(seriesID) ? "Retirer des favoris" : "Ajouter aux favoris")
        .accessibilityLabel(store.isFavorite(seriesID) ? "Retirer \(seriesID) des favoris" : "Ajouter \(seriesID) aux favoris")
    }
}

struct SeriesDetailView: View {
    @Environment(AppStore.self) private var store
    let series: MarketSeries
    var compact = false

    var body: some View {
        @Bindable var store = store
        Surface {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(series.name).font(.system(size: 16, weight: .medium))
                        Text(series.subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 5)
                    OriginBadge(series: series)
                }
                VStack(alignment: .leading, spacing: 9) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(series.latest.map { MarketFormat.number($0.value, digits: series.fractionDigits) } ?? "—")
                            .font(.system(size: compact ? 34 : 43, weight: .medium)).tracking(-1.5).monospacedDigit()
                        Text(series.unit.symbol).font(.system(size: 22)).foregroundStyle(.secondary)
                    }
                    Text(MarketFormat.change(series, period: store.period) + " · " + store.period.title)
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                VStack(spacing: 14) {
                    HStack {
                        Text(series.category == .funds ? "Valeur liquidative en euros" : series.unit == .percent ? "Taux en %" : series.unit.symbol + " pour 1 EUR")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                        Spacer()
                    }
                    Picker("Période de l’historique", selection: $store.period) {
                        ForEach(HistoryPeriod.allCases) { period in
                            Text(period.title).tag(period).disabled(period == .year && !series.isDemo)
                        }
                    }
                    .pickerStyle(.segmented).labelsHidden()
                    HistoryChart(series: series, period: store.period, height: compact ? 125 : 185)
                }
                Divider()
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "calendar").foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Observation du " + MarketFormat.date(series.latest?.date)).font(.system(size: 11, weight: .medium))
                        if series.isDemo {
                            Text(series.category == .funds ? "Fonds fictif · la part et la devise sont suivies séparément." : "Valeurs fictives pour explorer l’application.")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        } else {
                            Text("Taux de référence quotidien · historique BCE de 90 jours.")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                            if let url = series.sourceURL {
                                Link(series.source, destination: url).font(.system(size: 11))
                            }
                        }
                    }
                }
                if series.category == .funds {
                    Button { store.isAlertSheetPresented = true } label: {
                        Label("Créer une alerte", systemImage: "bell.badge").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                }
            }
        }
    }
}

struct FavoritesView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        if store.favorites.isEmpty {
            ContentUnavailableView("Votre veille commence ici", systemImage: "star",
                                   description: Text("Ajoutez des indicateurs ou des fonds avec l’étoile pour les retrouver ici."))
                .frame(maxWidth: .infinity, minHeight: 380)
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(store.favorites) { series in
                    IndicatorTile(series: series) {
                        store.show(series)
                        if series.category != .funds { store.section = .overview }
                    }
                }
            }
        }
    }
}
