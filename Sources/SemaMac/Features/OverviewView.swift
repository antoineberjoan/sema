import SwiftUI
import MarketCore

struct OverviewView: View {
    @Environment(AppStore.self) private var store
    var showsQuickSwitcher = false

    var body: some View {
        if let selected = store.selectedSeries {
            VStack(spacing: 32) {
                SeriesDetailView(series: selected, focus: true)
                if showsQuickSwitcher {
                    ScrollView(.horizontal) {
                        HStack(spacing: 28) {
                            ForEach(store.followedSeries) { item in
                                let current = item.id == selected.id
                                Button { store.show(item) } label: {
                                    Text(store.displayedSeries(item).name)
                                        .font(.system(size: 12)).foregroundStyle(current ? .primary : .secondary)
                                        .padding(.bottom, 10)
                                        .overlay(alignment: .bottom) {
                                            if current { Rectangle().frame(height: 1).foregroundStyle(.primary) }
                                        }
                                }
                                .buttonStyle(.plain).accessibilityAddTraits(current ? .isSelected : [])
                            }
                        }.padding(.horizontal, 2)
                    }
                    .scrollIndicators(.hidden).fixedSize(horizontal: false, vertical: true)
                }
            }
        } else {
            ContentUnavailableView {
                Label("Vos repères, à votre façon.", systemImage: "chart.xyaxis.line")
            } description: {
                Text("Explorez les catalogues pour composer votre sélection.")
            } actions: {
                Button("Explorer les repères") { store.section = .explorer }.buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, minHeight: 450)
        }
    }
}

struct IndicatorTile: View {
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
                VStack(alignment: .leading, spacing: compact ? 14 : 10) {
                    HStack(spacing: 6) {
                        Text(displayed.name).font(.system(size: 13, weight: .medium)).lineLimit(1)
                        if series.isDemo { Text("Démo").font(.system(size: 11)).foregroundStyle(.secondary) }
                        if !store.isSourceEnabled(for: series.id) { Image(systemName: "pause.circle").foregroundStyle(.secondary).help("Source désactivée · historique conservé") }
                    }
                    .padding(.trailing, series.exchangeRatePair == nil ? 22 : 48)
                    HStack(alignment: .firstTextBaseline) {
                        Text(MarketFormat.value(displayed))
                            .font(.system(size: compact ? 24 : 22, weight: .regular))
                            .tracking(-0.6).monospacedDigit().lineLimit(1).minimumScaleFactor(0.85)
                        Spacer(minLength: 6)
                        Text(MarketFormat.change(displayed, period: .month))
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
            .accessibilityLabel("\(displayed.name), \(MarketFormat.value(displayed))\(series.isDemo ? ", démonstration" : "")")
            .accessibilityValue(selected ? "Sélectionné" : "")
            HStack(spacing: 0) {
                ExchangeDirectionButton(series: series)
                FavoriteButton(seriesID: series.id, seriesName: displayed.name)
            }.padding(8)
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
    let seriesName: String
    var body: some View {
        Button { store.toggleFavorite(seriesID) } label: {
            Image(systemName: store.isFavorite(seriesID) ? "star.fill" : "star")
                .font(.system(size: 12)).foregroundStyle(store.isFavorite(seriesID) ? accent : Color.secondary)
                .frame(width: 26, height: 26).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(store.isFavorite(seriesID) ? "Retirer des favoris" : "Ajouter aux favoris")
        .accessibilityLabel(store.isFavorite(seriesID) ? "Retirer \(seriesName) des favoris" : "Ajouter \(seriesName) aux favoris")
    }
}

struct ExchangeDirectionButton: View {
    @Environment(AppStore.self) private var store
    @Environment(\.semaAccent) private var accent
    let series: MarketSeries

    var body: some View {
        if let pair = series.exchangeRatePair {
            let inverted = store.isExchangeRateInverted(series)
            let target = inverted ? pair.publishedDescription : pair.inverseDescription
            Button { store.toggleExchangeRateDirection(series) } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12)).foregroundStyle(inverted ? accent : Color.secondary)
                    .frame(width: 26, height: 26).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!series.canInvertExchangeRate)
            .help(series.canInvertExchangeRate ? "Afficher " + target : "Inversion indisponible : les cours doivent être strictement positifs.")
            .accessibilityLabel("Inverser la paire · afficher " + target)
        }
    }
}

struct SeriesDetailView: View {
    @Environment(AppStore.self) private var store
    let series: MarketSeries
    var preview = false
    var focus = false
    @State private var period: HistoryPeriod = .year
    @State private var showsSource = false

    var body: some View {
        let displayed = store.displayedSeries(series)
        VStack(alignment: .leading, spacing: focus ? 28 : 22) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayed.name)
                        .font(.system(size: focus ? 14 : 18, weight: focus ? .regular : .semibold))
                        .foregroundStyle(focus ? .secondary : .primary).textSelection(.enabled)
                    if !focus {
                        Text(displayed.subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                if focus {
                    periodPicker.frame(maxWidth: 320)
                } else {
                    ExchangeDirectionButton(series: series)
                    OriginBadge(series: series)
                }
            }
            if !store.isSourceEnabled(series.statisticalDescriptor?.dataset.source.rawValue ?? store.sourceID(for: series.id)) {
                Label("Source désactivée · historique conservé, actualisations et alertes en pause.", systemImage: "pause.circle")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(displayed.latest.map { MarketFormat.number($0.value, digits: displayed.fractionDigits) } ?? "—")
                        .font(.system(size: focus ? 72 : 40, weight: focus ? .regular : .medium))
                        .tracking(focus ? -2.5 : -1.2).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.55)
                    if focus {
                        Text(displayed.displayUnit).font(.system(size: 22)).foregroundStyle(.secondary)
                        Spacer(minLength: 12)
                        ExchangeDirectionButton(series: series)
                        FavoriteButton(seriesID: series.id, seriesName: displayed.name)
                    }
                }
                if !focus { Text(displayed.displayUnit).font(.system(size: 12)).foregroundStyle(.secondary) }
                if series.latest != nil {
                    Text(MarketFormat.change(displayed, period: period) + " sur " + period.title)
                        .font(.system(size: focus ? 13 : 11)).foregroundStyle(.secondary)
                }
            }
            if series.observations.isEmpty {
                ContentUnavailableView("Historique indisponible", systemImage: "chart.xyaxis.line",
                    description: Text("La description de cette série reste consultable. Aucune observation numérique n’a été reçue."))
                    .frame(height: 190)
            } else {
                if !focus { periodPicker }
                HistoryChart(series: displayed, period: period, height: focus ? 250 : preview ? 170 : 235, showsReading: !focus)
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
                            .buttonStyle(.borderless).disabled(!store.canLoadFullHistory(series))
                    }
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Group {
                    if focus {
                        Button { showsSource = true } label: {
                            Text((series.isDemo ? "données fictives · " : "") + compactObservationPeriod)
                        }
                        .buttonStyle(.plain)
                        .help("Source et définition")
                        .accessibilityLabel("Source et définition, " + observationPeriod)
                        .popover(isPresented: $showsSource) {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(series.source).font(.system(size: 13, weight: .medium))
                                    Text(observationPeriod).font(.system(size: 11)).foregroundStyle(.secondary)
                                    sourceDetails
                                    metadata
                                }.padding(22)
                            }
                            .frame(width: 380)
                            .frame(maxHeight: 440)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    } else { Label(observationPeriod, systemImage: "calendar") }
                }
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if store.isFollowing(series.id) {
                    Button {
                        store.prepareAlert(for: series)
                    } label: { Label("Créer une alerte", systemImage: "bell.badge") }
                    .buttonStyle(.borderless).font(.system(size: 12)).disabled(!series.canAlert || !store.isSourceEnabled(for: series.id))
                }
            }
            if !focus, store.isExchangeRateInverted(series), let pair = series.exchangeRatePair {
                Text("Lecture inversée calculée à partir de la série publiée. Les alertes restent exprimées en " + pair.publishedDescription + ".")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            if !series.canAlert {
                Text("Alertes suspendues : l’unité ou son échelle n’est pas interprétée. Les codes restent disponibles dans les informations de source.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            if let error = store.seriesErrors[series.id] {
                Label(error + " Les observations conservées restent visibles.", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            if !focus {
                DisclosureGroup("Source et définition") { sourceDetails }
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                metadata
            }
        }
        .modifier(SeriesDetailSurface(focus: focus))
        .onChange(of: series.id, initial: true) { _, _ in
            period = series.supports(.year) ? .year : .all
            showsSource = false
        }
    }

    private var sourceDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            if focus {
                Text(store.displayedSeries(series).subtitle).textSelection(.enabled)
                if store.isExchangeRateInverted(series), let pair = series.exchangeRatePair {
                    Text("Lecture inversée calculée à partir de la série publiée. Les alertes restent exprimées en " + pair.publishedDescription + ".")
                }
            }
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
                } else if let descriptor = series.statisticalDescriptor {
                    Text(descriptor.definition).textSelection(.enabled)
                    LabeledContent("Producteur", value: descriptor.fields["PRODUCER"] ?? series.source)
                    LabeledContent("Fréquence", value: descriptor.frequency.title)
                    LabeledContent("Unité et échelle", value: descriptor.displayUnit)
                    Text(descriptor.dataset.source.attribution).textSelection(.enabled)
                    Link("Conditions de réutilisation ↗", destination: descriptor.dataset.source.termsURL)
                } else { Text(series.frequency?.title ?? "Fréquence non renseignée") }
                if let status = series.latest?.status { LabeledContent("Statut de l’observation", value: status) }
                if let updated = series.latest?.updatedAt { LabeledContent("Mise à jour source", value: MarketFormat.date(updated)) }
                if let sync = series.syncedAt { LabeledContent("Téléchargé le", value: MarketFormat.date(sync)) }
                let accessPoints = SeriesEquivalence.accessPoints(for: series)
                if accessPoints.count > 1 {
                    Text("Accès à cette même série").fontWeight(.medium)
                    ForEach(accessPoints, id: \.sourceID) { point in
                        Link("\(store.sourceName(point.sourceID)) ↗", destination: point.url)
                    }
                } else if let url = series.sourceURL { Link("Consulter la source ↗", destination: url) }
                Button("Recharger l’historique complet") { store.loadAllHistory(series, reload: true) }
                    .buttonStyle(.borderless).disabled(!store.canLoadFullHistory(series) || store.historyLoadingID != nil)
            }
        }
        .font(.system(size: 11)).foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
    }

    @ViewBuilder private var metadata: some View {
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
        if let descriptor = series.statisticalDescriptor {
            DisclosureGroup("Métadonnées de la source") {
                VStack(alignment: .leading, spacing: 7) {
                    Text(descriptor.key).font(.system(size: 10, design: .monospaced)).textSelection(.enabled)
                    ForEach(descriptor.fields.keys.sorted(), id: \.self) { key in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(key).fontWeight(.medium)
                            Text(descriptor.fields[key] ?? "").textSelection(.enabled)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.font(.system(size: 10)).padding(.top, 8)
            }.font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    private var compactObservationPeriod: String {
        guard let latest = series.latest else { return "source" }
        if let end = latest.periodEnd, end != latest.date {
            return MarketFormat.date(latest.date) + " – " + MarketFormat.date(end)
        }
        return MarketFormat.date(latest.date)
    }

    private var periodPicker: some View {
        Picker("Période de l’historique", selection: $period) {
            ForEach(HistoryPeriod.allCases.filter { $0 == .all || series.supports($0) }) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented).labelsHidden()
    }

    private var observationPeriod: String {
        guard let latest = series.latest else { return "Aucune observation disponible" }
        if let end = latest.periodEnd, end != latest.date {
            return "Période du " + MarketFormat.date(latest.date) + " au " + MarketFormat.date(end)
        }
        return "Observation du " + MarketFormat.date(latest.date)
    }
}

private struct SeriesDetailSurface: ViewModifier {
    let focus: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if focus { content }
        else { Surface { content } }
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
