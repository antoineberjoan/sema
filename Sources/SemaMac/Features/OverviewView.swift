import SwiftUI
import MarketCore

struct OverviewView: View {
    @Environment(AppStore.self) private var store
    @State private var removal: MarketSeries?

    var body: some View {
        if store.followedSeries.isEmpty {
            ContentUnavailableView {
                Label("Vos repères, à votre façon.", systemImage: "chart.xyaxis.line")
            } description: {
                Text("Explorez le catalogue Webstat pour composer votre panorama.")
            } actions: {
                Button("Explorer les repères") { store.section = .explorer }.buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, minHeight: 450)
        } else {
            HStack(alignment: .top, spacing: 26) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Mes repères").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                        Spacer()
                        Button { store.section = .explorer } label: { Image(systemName: "plus") }
                            .buttonStyle(.borderless).help("Ajouter un repère")
                    }.padding(.horizontal, 12)
                    List {
                        ForEach(store.followedSeries) { item in
                            IndicatorTile(series: item, selected: store.selectedSeriesID == item.id) { store.show(item) }
                                .listRowInsets(EdgeInsets()).listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .contextMenu {
                                    Button("Monter") { store.moveFollowed(item.id, by: -1) }
                                    Button("Descendre") { store.moveFollowed(item.id, by: 1) }
                                    Divider()
                                    Button("Retirer de mes repères", role: .destructive) { removal = item }
                                }
                        }
                        .onMove { store.moveFollowed(from: $0, to: $1) }
                    }
                    .listStyle(.plain).scrollContentBackground(.hidden).frame(minHeight: 510)
                }
                .frame(width: 285)
                if let selected = store.selectedSeries {
                    SeriesDetailView(series: selected).frame(minWidth: 360, maxWidth: .infinity)
                }
            }
            .confirmationDialog("Retirer ce repère ?", isPresented: Binding(get: { removal != nil }, set: { if !$0 { removal = nil } }), titleVisibility: .visible) {
                Button("Retirer de mes repères", role: .destructive) { if let removal { _ = store.unfollow(removal.id) }; removal = nil }
                Button("Annuler", role: .cancel) { removal = nil }
            } message: {
                Text("Ses alertes seront conservées et mises en pause. Son historique restera en cache.")
            }
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
    var preview = false
    @State private var period: HistoryPeriod = .year

    var body: some View {
        Surface {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(series.name).font(.system(size: 18, weight: .semibold)).textSelection(.enabled)
                        Text(series.subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    OriginBadge(series: series)
                }
                VStack(alignment: .leading, spacing: 7) {
                    Text(series.latest.map { MarketFormat.number($0.value, digits: series.fractionDigits) } ?? "—")
                        .font(.system(size: 40, weight: .medium)).tracking(-1.2).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Text(series.displayUnit).font(.system(size: 12)).foregroundStyle(.secondary)
                    if series.latest != nil {
                        Text(MarketFormat.change(series, period: period) + " sur " + period.title)
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
                if series.observations.isEmpty {
                    ContentUnavailableView("Historique indisponible", systemImage: "chart.xyaxis.line",
                        description: Text("La description de cette série reste consultable. Aucune observation numérique n’a été reçue."))
                        .frame(height: 190)
                } else {
                    Picker("Période de l’historique", selection: $period) {
                        ForEach(HistoryPeriod.allCases.filter { $0 == .all || series.supports($0) }) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented).labelsHidden()
                    HistoryChart(series: series, period: period, height: preview ? 170 : 235)
                }
                if period == .all, !series.isDemo, series.hasCompleteHistory != true {
                    HStack(spacing: 12) {
                        if store.historyLoadingID == series.id {
                            ProgressView().controlSize(.small)
                            Text(store.historyProgress ?? "Chargement…").font(.system(size: 11)).foregroundStyle(.secondary)
                            Spacer()
                            Button("Annuler") { store.cancelHistory() }.buttonStyle(.borderless)
                        } else {
                            Text("Couverture : depuis " + MarketFormat.date(series.observations.first?.date))
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                            Spacer()
                            Button("Charger tout l’historique") { store.loadAllHistory(series) }
                                .buttonStyle(.borderless).disabled(!store.hasWebstatKey || series.descriptor?.firstPeriod == nil)
                        }
                    }
                }
                HStack(alignment: .firstTextBaseline) {
                    Label("Observation du " + MarketFormat.date(series.latest?.date), systemImage: "calendar")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    if store.isFollowing(series.id) {
                        Button {
                            store.prepareAlert(for: series)
                        } label: { Label("Créer une alerte", systemImage: "bell.badge") }
                        .buttonStyle(.borderless).font(.system(size: 12)).disabled(!series.canAlert)
                    }
                }
                if !series.canAlert {
                    Text("Alertes suspendues : l’unité ou son échelle n’est pas interprétée. Les codes de la source restent disponibles ci-dessous.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                if let error = store.seriesErrors[series.id] {
                    Label(error + " Les observations conservées restent visibles.", systemImage: "exclamationmark.triangle")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                DisclosureGroup("Source et définition") {
                    VStack(alignment: .leading, spacing: 10) {
                        if series.isDemo { Text("Valeurs fictives pour explorer l’application.") }
                        else {
                            if let descriptor = series.descriptor {
                                Text(descriptor.definition).textSelection(.enabled)
                                LabeledContent("Producteur", value: descriptor.producer)
                                LabeledContent("Fréquence", value: descriptor.frequencyTitle)
                                LabeledContent("Unité et échelle", value: descriptor.displayUnit)
                                LabeledContent("Début publié", value: MarketFormat.date(descriptor.firstPeriod))
                                LabeledContent("Dernière période", value: MarketFormat.date(descriptor.lastPeriod))
                                if let base = descriptor.attributes["UNIT_INDEX_BASE"] { LabeledContent("Base de l’indice", value: base) }
                            } else { Text(series.frequency?.title ?? "Fréquence non renseignée") }
                            if let updated = series.latest?.updatedAt { LabeledContent("Mise à jour source", value: MarketFormat.date(updated)) }
                            if let sync = series.syncedAt { LabeledContent("Téléchargé le", value: MarketFormat.date(sync)) }
                            if let url = series.sourceURL { Link("Consulter sur Webstat ↗", destination: url) }
                            Button("Recharger l’historique complet") { store.loadAllHistory(series, reload: true) }
                                .buttonStyle(.borderless).disabled(!store.hasWebstatKey || store.historyLoadingID != nil)
                        }
                    }
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                }
                .font(.system(size: 11)).foregroundStyle(.secondary)
                if let descriptor = series.descriptor {
                    DisclosureGroup("Métadonnées de Webstat") {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(descriptor.key).font(.system(size: 10, design: .monospaced)).textSelection(.enabled)
                            ForEach(descriptor.raw.keys.sorted(), id: \.self) { key in
                                if let text = descriptor.raw[key]?.text {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(key).fontWeight(.medium)
                                        Text(text).textSelection(.enabled)
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }.font(.system(size: 10)).padding(.top, 8)
                    }.font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: series.id, initial: true) { _, _ in period = series.supports(.year) ? .year : .all }
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
