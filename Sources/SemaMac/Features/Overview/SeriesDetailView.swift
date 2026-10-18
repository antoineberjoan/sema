// Détail d’une série : valeur, variation, historique et métadonnées officielles.
import SwiftUI
import MarketCore

struct SeriesDetailView: View {
    private static let focusNameFont = Font.system(size: 14)
    private static let nameFont = Font.system(size: 18, weight: .semibold)
    private static let focusValueFont = Font.system(size: 72)
    private static let valueFont = Font.system(size: 40, weight: .medium)
    private static let focusSectionSpacing: CGFloat = 28
    private static let sectionSpacing: CGFloat = 22
    private static let headerSpacing: CGFloat = 12
    private static let titleSpacing: CGFloat = 6
    private static let periodPickerWidth: CGFloat = 320
    private static let valueSpacing: CGFloat = 7
    private static let focusValueTracking: CGFloat = -2.5
    private static let valueTracking: CGFloat = -1.2
    private static let valueMinimumScale: CGFloat = 0.55
    private static let actionSpacing: CGFloat = 12
    private static let previewChartHeight: CGFloat = 170
    private static let chartHeight: CGFloat = 235
    private static let metadataSpacing: CGFloat = 16
    private static let metadataPadding: CGFloat = 22
    private static let metadataWidth: CGFloat = 380
    private static let metadataMaxHeight: CGFloat = 440
    private static let sourceSpacing: CGFloat = 10
    private static let metadataFieldSpacing: CGFloat = 7
    private static let metadataLabelSpacing: CGFloat = 2
    @Environment(AppStore.self) private var store
    let series: MarketSeries
    var preview = false
    var focus = false
    @State private var period: HistoryPeriod = .year
    @State private var showsSource = false

    var body: some View {
        let displayed = store.displayedSeries(series)
        VStack(alignment: .leading, spacing: focus ? Self.focusSectionSpacing : Self.sectionSpacing) {
            HStack(alignment: .top, spacing: Self.headerSpacing) {
                VStack(alignment: .leading, spacing: Self.titleSpacing) {
                    Text(displayed.name)
                        .font(focus ? Self.focusNameFont : Self.nameFont)
                        .foregroundStyle(focus ? .secondary : .primary).textSelection(.enabled)
                    if !focus {
                        Text(displayed.subtitle).font(.callout).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                if focus {
                    periodPicker.frame(maxWidth: Self.periodPickerWidth)
                } else {
                    ExchangeDirectionButton(series: series)
                    OriginBadge(series: series)
                }
            }
            if !store.isSourceEnabled(series.marketInstrument?.provider.rawValue ?? series.statisticalDescriptor?.dataset.source.rawValue ?? store.sourceID(for: series.id)) {
                Label("Source désactivée · historique conservé, actualisations et alertes en pause.", systemImage: "pause.circle")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: Self.valueSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: SemaTheme.minorSpacing) {
                    Text(displayed.latest.map { MarketFormat.number($0.value, digits: displayed.fractionDigits) } ?? "—")
                        .font(focus ? Self.focusValueFont : Self.valueFont)
                        .tracking(focus ? Self.focusValueTracking : Self.valueTracking).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(Self.valueMinimumScale)
                    if focus {
                        Text(displayed.displayUnit).font(.title).foregroundStyle(.secondary)
                        Spacer(minLength: Self.actionSpacing)
                        ExchangeDirectionButton(series: series)
                        FavoriteButton(seriesID: series.id, seriesName: displayed.name)
                    }
                }
                if !focus { Text(displayed.displayUnit).font(.callout).foregroundStyle(.secondary) }
                if series.latest != nil {
                    Text(MarketFormat.change(displayed, period: period) + " sur " + period.title)
                        .font(focus ? .body : .subheadline).foregroundStyle(.secondary)
                }
            }
            if series.observations.isEmpty {
                ContentUnavailableView("Historique indisponible", systemImage: "chart.xyaxis.line",
                    description: Text("La description de cette série reste consultable. Aucune observation numérique n’a été reçue."))
                    .frame(height: HistoryChart.defaultHeight)
            } else {
                if !focus { periodPicker }
                HistoryChart(series: displayed, period: period, height: focus ? nil : preview ? Self.previewChartHeight : Self.chartHeight, showsReading: !focus)
            }
            if period == .all, !series.isDemo, series.hasCompleteHistory != true {
                HStack(spacing: Self.actionSpacing) {
                    if store.historyLoadingID == series.id {
                        ProgressView().controlSize(.small)
                        Text(store.historyProgress ?? "Chargement…").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Button("Annuler") { store.cancelHistory() }.buttonStyle(.borderless)
                    } else {
                        Text("Couverture : depuis " + MarketFormat.date(series.observations.first?.date))
                            .font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        if series.marketInstrument == nil {
                            Button("Charger tout l’historique") { store.loadAllHistory(series) }
                                .buttonStyle(.borderless).disabled(!store.canLoadFullHistory(series))
                        }
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
                        .accessibilityLabel((series.isDemo ? "Données fictives, " : "") + "source et définition, " + observationPeriod)
                        .popover(isPresented: $showsSource) {
                            ScrollView {
                                VStack(alignment: .leading, spacing: Self.metadataSpacing) {
                                    Text(series.source).font(.body.weight(.medium))
                                    Text(observationPeriod).font(.subheadline).foregroundStyle(.secondary)
                                    sourceDetails
                                    metadata
                                }.padding(Self.metadataPadding)
                            }
                            .frame(width: Self.metadataWidth)
                            .frame(maxHeight: Self.metadataMaxHeight)
                            .fixedSize(horizontal: false, vertical: true)
                            .onExitCommand { showsSource = false }
                        }
                    } else { Label(observationPeriod, systemImage: "calendar") }
                }
                .font(.subheadline).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: SemaTheme.minorSpacing)
                if store.isFollowing(series.id) {
                    Button {
                        store.prepareAlert(for: series)
                    } label: { Label("Créer une alerte", systemImage: "bell.badge") }
                    .buttonStyle(.borderless).font(.callout).disabled(!series.canAlert || !store.isSourceEnabled(for: series.id))
                }
            }
            if !focus, store.isExchangeRateInverted(series), let pair = series.exchangeRatePair {
                Text("Lecture inversée calculée à partir de la série publiée. Les alertes restent exprimées en " + pair.publishedDescription + ".")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if !series.canAlert {
                Text("Alertes suspendues : l’unité ou son échelle n’est pas interprétée. Les codes restent disponibles dans les informations de source.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if let error = store.seriesErrors[series.id] {
                Label(error + " Les observations conservées restent visibles.", systemImage: "exclamationmark.triangle")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if !focus {
                DisclosureGroup("Source et définition") { sourceDetails }
                    .font(.subheadline).foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: Self.sourceSpacing) {
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
        .font(.subheadline).foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, SemaTheme.minorSpacing)
    }

    @ViewBuilder private var metadata: some View {
        if let descriptor = series.descriptor {
            DisclosureGroup("Métadonnées de Webstat") {
                VStack(alignment: .leading, spacing: Self.metadataFieldSpacing) {
                    Text(descriptor.key).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    ForEach(descriptor.raw.keys.sorted(), id: \.self) { key in
                        if let text = descriptor.raw[key]?.text {
                            VStack(alignment: .leading, spacing: Self.metadataLabelSpacing) {
                                Text(key).fontWeight(.medium)
                                Text(text).textSelection(.enabled)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }.font(.caption).padding(.top, SemaTheme.minorSpacing)
            }.font(.subheadline).foregroundStyle(.secondary)
        }
        if let descriptor = series.statisticalDescriptor {
            DisclosureGroup("Métadonnées de la source") {
                VStack(alignment: .leading, spacing: Self.metadataFieldSpacing) {
                    Text(descriptor.key).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    ForEach(descriptor.fields.keys.sorted(), id: \.self) { key in
                        VStack(alignment: .leading, spacing: Self.metadataLabelSpacing) {
                            Text(key).fontWeight(.medium)
                            Text(descriptor.fields[key] ?? "").textSelection(.enabled)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.font(.caption).padding(.top, SemaTheme.minorSpacing)
            }.font(.subheadline).foregroundStyle(.secondary)
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
            ForEach(HistoryPeriod.visible.filter { $0 == .all || series.supports($0) }) { Text($0.title).tag($0) }
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
