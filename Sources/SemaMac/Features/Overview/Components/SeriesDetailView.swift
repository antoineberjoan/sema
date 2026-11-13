// Détail d’une série : valeur, variation, historique et métadonnées officielles.
import SemaDesign
import SwiftUI
import MarketCore

struct SeriesDetailView: View {
    private static let focusSectionSpacing = DesignSpace.groupGap
    private static let sectionSpacing = DesignSpace.groupGap
    private static let headerSpacing = DesignSpace.fieldGap
    private static let titleSpacing = DesignSpace.titleGap
    private static let valueSpacing = DesignSpace.titleGap
    private static let actionSpacing = DesignSpace.fieldGap
    private static let sourceSpacing = DesignSpace.fieldGap
    private static let metadataFieldSpacing = DesignSpace.titleGap
    private static let metadataLabelSpacing = DesignSpace.listGapDense
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    let series: MarketSeries
    var preview = false
    var isFocus = false
    /// Les aperçus hors Focus gardent leur période ; Focus partage le choix du hub et du bandeau.
    @State private var localPeriod: HistoryPeriod = .year
    @State private var isExplanationShown = false

    private var period: HistoryPeriod { isFocus ? store.period(for: series) : localPeriod }

    var body: some View {
        if series.observations.isEmpty { noData } else { populated }
    }

    private var noData: some View {
        let displayed = store.displayedSeries(series)
        return VStack(alignment: .leading, spacing: Self.sectionSpacing) {
            VStack(alignment: .leading, spacing: Self.titleSpacing) {
                Text(MarketFormat.name(displayed))
                    .typeRole(isFocus ? .small : .section)
                    .foregroundStyle(isFocus ? DesignColor.textMuted : DesignColor.text).textSelection(.enabled)
                if !isFocus {
                    Text(displayed.subtitle).typeRole(.small).foregroundStyle(DesignColor.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            ContentUnavailableView {
                Label("Pas encore de données", systemImage: "chart.xyaxis.line")
            } description: {
                Text(isWebstatKeyMissing ? "Connectez votre clé Webstat pour afficher ce repère."
                     : "Aucune observation n’a été reçue pour l’instant.")
            } actions: {
                if isWebstatKeyMissing {
                    Button("Connecter Webstat") { store.settingsTab = .sources; openSettings() }
                        .buttonStyle(.borderedProminent).tint(DesignColor.accent(store.palette))
                }
            }
            .frame(maxWidth: .infinity, minHeight: DesignLayout.historyChartDefaultHeight, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(SeriesDetailSurface(isFocus: isFocus))
    }

    private var isWebstatKeyMissing: Bool { store.sourceID(for: series.id) == "webstat" && !store.hasWebstatKey }

    private var populated: some View {
        let displayed = store.displayedSeries(series)
        let explanation = SeriesExplanation(series: series, period: period,
            inverted: store.isExchangeRateInverted(series),
            formatNumber: { MarketFormat.number($0, digits: $1) })
        return VStack(alignment: .leading, spacing: isFocus ? Self.focusSectionSpacing : Self.sectionSpacing) {
            HStack(alignment: .top, spacing: Self.headerSpacing) {
                VStack(alignment: .leading, spacing: Self.titleSpacing) {
                    Text(MarketFormat.name(displayed))
                        .typeRole(isFocus ? .small : .section)
                        .foregroundStyle(isFocus ? DesignColor.textMuted : DesignColor.text).textSelection(.enabled)
                    if !isFocus {
                        Text(displayed.subtitle).typeRole(.small).foregroundStyle(DesignColor.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                if isFocus {
                    PeriodTabs(periods: availablePeriods, selection: period) { store.setPeriod($0) }
                } else {
                    ExchangeDirectionButton(series: series)
                    OriginBadge(series: series)
                }
            }
            if !store.isSourceEnabled(series.marketInstrument?.provider.rawValue ?? series.statisticalDescriptor?.dataset.source.rawValue ?? store.sourceID(for: series.id)) {
                Label("Source désactivée · historique conservé, actualisations et alertes en pause.", systemImage: "pause.circle")
                    .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
            if isFocus {
                focusHeadline(displayed)
            } else {
                VStack(alignment: .leading, spacing: Self.valueSpacing) {
                    Text(displayed.latest.map { MarketFormat.number($0.value, digits: displayed.fractionDigits) } ?? "—")
                        .typeRole(.figure)
                        .lineLimit(1).minimumScaleFactor(CGFloat(DesignMeasure.seriesDetailValueMinimumScale))
                    Text(MarketFormat.unit(displayed)).typeRole(.small).foregroundStyle(DesignColor.textMuted)
                    if series.latest != nil {
                        Text(MarketFormat.change(displayed, period: period) + " sur " + period.title)
                            .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                    }
                }
            }
            if let explanation, isFocus || explanation.reading != nil || explanation.implication != nil {
                DisclosureGroup("Comprendre", isExpanded: $isExplanationShown) {
                    SeriesExplanationView(explanation: explanation)
                }
                .typeRole(.small).fixedSize(horizontal: false, vertical: true)
            }
            if !isFocus { periodPicker }
            HistoryChart(series: displayed, period: period, height: isFocus ? nil : preview ? DesignLayout.seriesDetailPreviewChartHeight : DesignLayout.seriesDetailChartHeight, isReadingShown: !isFocus)
            if period == .all, series.hasCompleteHistory != true {
                HStack(spacing: Self.actionSpacing) {
                    if store.historyLoadingID == series.id {
                        ProgressView().controlSize(.small)
                        Text(store.historyProgress ?? "Chargement…").typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                        Spacer()
                        Button("Annuler") { store.cancelHistory() }.buttonStyle(.borderless)
                    } else {
                        Text("Couverture : depuis " + MarketFormat.date(series.observations.first?.date))
                            .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
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
                    if isFocus {
                    Text(selectedPeriodLabel)
                    } else { Label(selectedPeriodLabel, systemImage: "calendar") }
                }
                .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: DesignSpace.fieldGap)
                if !isFocus { alertButton }
            }
            if !isFocus, store.isExchangeRateInverted(series), let pair = series.exchangeRatePair {
                Text("Lecture inversée calculée à partir de la série publiée. Les alertes restent exprimées en " + pair.publishedDescription + ".")
                    .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
            if !series.canAlert {
                Text("Alertes indisponibles pour cette unité.")
                    .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
            if let error = store.seriesErrors[series.id] {
                Label(error + " Les observations conservées restent visibles.", systemImage: "exclamationmark.triangle")
                    .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
            if !isFocus {
                DisclosureGroup("Source et définition") { sourceDetails }
                    .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                metadata
            }
        }
        .modifier(SeriesDetailSurface(isFocus: isFocus))
        .disclosureGroupStyle(RowDisclosureStyle())
        .inspector(isPresented: contextBinding) {
            MoveContextView(series: series)
                .inspectorColumnWidth(min: DesignLayout.seriesDetailInspectorMinWidth, ideal: DesignLayout.seriesDetailInspectorIdealWidth, max: DesignLayout.seriesDetailInspectorMaxWidth)
        }
        .onChange(of: series.id, initial: true) { _, _ in
            localPeriod = series.supports(.year) ? .year : .all
            isExplanationShown = false
        }
    }

    private func focusHeadline(_ displayed: MarketSeries) -> some View {
        HStack(spacing: DesignSpace.groupGap) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: DesignSpace.groupGap) {
                    focusValue(displayed)
                    focusActions(displayed)
                }
                VStack(alignment: .leading, spacing: DesignSpace.fieldGap) {
                    focusValue(displayed)
                    focusActions(displayed)
                }
            }
            Spacer(minLength: DesignSpace.fieldGap)
            ExchangeDirectionButton(series: series)
            FavoriteButton(seriesID: series.id, seriesName: MarketFormat.name(displayed))
        }
    }

    private func focusActions(_ displayed: MarketSeries) -> some View {
        VStack(alignment: .leading, spacing: DesignSpace.fieldGap) {
            variationBadge(displayed)
            alertButton
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder private var alertButton: some View {
        if store.isFollowing(series.id) {
            HStack(spacing: DesignSpace.fieldGap) {
                WatchButton(series: series)
                if isFocus {
                    Button { store.isContextPresented.toggle() } label: { Label("Pourquoi ?", systemImage: "text.magnifyingglass") }
                        .buttonStyle(.bordered).controlSize(.small)
                        .help("Faits datés de la séance : vos autres repères, l’agenda, les communiqués et les titres.")
                }
            }
        }
    }

    /// Seul Focus ouvre l’inspecteur ; les aperçus du catalogue restent compacts.
    private var contextBinding: Binding<Bool> {
        Binding(get: { isFocus && store.isContextPresented }, set: { store.isContextPresented = $0 })
    }

    private func focusValue(_ displayed: MarketSeries) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignSpace.titleGap) {
            Text(displayed.latest.map { MarketFormat.number($0.value, digits: displayed.fractionDigits) } ?? "—")
                .typeRole(.hero)
                .lineLimit(1).minimumScaleFactor(CGFloat(DesignMeasure.seriesDetailValueMinimumScale))
            Text(MarketFormat.unit(displayed)).typeRole(.small).foregroundStyle(DesignColor.textMuted)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func variationBadge(_ displayed: MarketSeries) -> some View {
        if displayed.change(for: period) != nil {
            Text(MarketFormat.change(displayed, period: period) + " sur " + period.title)
                .typeRole(.tag).fontWeight(.medium).monospacedDigit().lineLimit(1)
                .foregroundStyle(DesignColor.accentText(store.palette))
                .padding(.horizontal, DesignSpace.markInsetInline)
                .padding(.vertical, DesignSpace.markInset)
                .background(DesignColor.selection(store.palette), in: RoundedRectangle(cornerRadius: DesignRadius.mark))
        } else if series.latest != nil {
            Text(MarketFormat.change(displayed, period: period))
                .typeRole(.small).foregroundStyle(DesignColor.textMuted)
        }
    }

    private var sourceDetails: some View {
        VStack(alignment: .leading, spacing: Self.sourceSpacing) {
            if MarketFormat.name(series) != series.name {
                LabeledContent("Libellé officiel", value: series.name).textSelection(.enabled)
            }
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
                if let sync = series.syncedAt {
                    LabeledContent("Actualisé dans sema", value: MarketFormat.date(sync) + " à " + sync.formatted(date: .omitted, time: .shortened))
                }
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
        .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, DesignSpace.rowInset)
    }

    @ViewBuilder private var metadata: some View {
        if let descriptor = series.descriptor {
            DisclosureGroup("Métadonnées de Webstat") {
                VStack(alignment: .leading, spacing: Self.metadataFieldSpacing) {
                    Text(descriptor.key).typeRole(.code).textSelection(.enabled)
                    ForEach(descriptor.raw.keys.sorted(), id: \.self) { key in
                        if let text = descriptor.raw[key]?.text {
                            VStack(alignment: .leading, spacing: Self.metadataLabelSpacing) {
                                Text(key).fontWeight(.medium)
                                Text(text).textSelection(.enabled)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }.typeRole(.micro).padding(.top, DesignSpace.rowInset)
            }.typeRole(.caption).foregroundStyle(DesignColor.textMuted)
        }
        if let descriptor = series.statisticalDescriptor {
            DisclosureGroup("Métadonnées de la source") {
                VStack(alignment: .leading, spacing: Self.metadataFieldSpacing) {
                    Text(descriptor.key).typeRole(.code).textSelection(.enabled)
                    ForEach(descriptor.fields.keys.sorted(), id: \.self) { key in
                        VStack(alignment: .leading, spacing: Self.metadataLabelSpacing) {
                            Text(key).fontWeight(.medium)
                            Text(descriptor.fields[key] ?? "").textSelection(.enabled)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.typeRole(.micro).padding(.top, DesignSpace.rowInset)
            }.typeRole(.caption).foregroundStyle(DesignColor.textMuted)
        }
    }

    private var selectedPeriodLabel: String {
        let observations = series.history(for: period)
        guard let first = observations.first?.date, let last = observations.last?.date else {
            return period.title
        }
        return "Période du " + MarketFormat.date(first) + " au " + MarketFormat.date(last)
    }

    private var availablePeriods: [HistoryPeriod] { HistoryPeriod.visible.filter { $0 == .all || series.supports($0) } }

    private var periodPicker: some View {
        Picker("Période de l’historique", selection: $localPeriod) {
            ForEach(availablePeriods) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented).labelsHidden()
    }
}

private struct SeriesDetailSurface: ViewModifier {
    let isFocus: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if isFocus { content }
        else {
            content
                .padding(DesignSpace.pageInsetNarrow)
                .background(DesignColor.surfaceRaised, in: RoundedRectangle(cornerRadius: DesignRadius.card))
                .elevation(DesignElevation.raised)
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card))
        }
    }
}
