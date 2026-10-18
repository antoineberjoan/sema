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
    private static let focusValueTracking: CGFloat = -2.5
    private static let valueTracking: CGFloat = -1.2
    private static let valueMinimumScale: CGFloat = 0.55
    private static let valueSpacing: CGFloat = 7
    private static let actionSpacing: CGFloat = 12
    private static let previewChartHeight: CGFloat = 170
    private static let chartHeight: CGFloat = 235
    private static let sourceSpacing: CGFloat = 10
    private static let metadataFieldSpacing: CGFloat = 7
    private static let metadataLabelSpacing: CGFloat = 2
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    let series: MarketSeries
    var preview = false
    var focus = false
    @State private var period: HistoryPeriod = .year
    @State private var showsExplanation = false

    var body: some View {
        if series.observations.isEmpty { noData } else { populated }
    }

    private var noData: some View {
        let displayed = store.displayedSeries(series)
        return VStack(alignment: .leading, spacing: Self.sectionSpacing) {
            VStack(alignment: .leading, spacing: Self.titleSpacing) {
                Text(MarketFormat.name(displayed))
                    .font(focus ? Self.focusNameFont : Self.nameFont)
                    .foregroundStyle(focus ? .secondary : .primary).textSelection(.enabled)
                if !focus {
                    Text(displayed.subtitle).font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            ContentUnavailableView {
                Label("Pas encore de données", systemImage: "chart.xyaxis.line")
            } description: {
                Text(needsWebstatKey ? "Connectez votre clé Webstat pour afficher ce repère."
                     : "Aucune observation n’a été reçue pour l’instant.")
            } actions: {
                if needsWebstatKey {
                    Button("Connecter Webstat") { store.settingsTab = .sources; openSettings() }
                        .buttonStyle(.borderedProminent).tint(store.palette.accent)
                }
            }
            .frame(maxWidth: .infinity, minHeight: HistoryChart.defaultHeight)
        }
        .modifier(SeriesDetailSurface(focus: focus))
    }

    private var needsWebstatKey: Bool { store.sourceID(for: series.id) == "webstat" && !store.hasWebstatKey }

    private var populated: some View {
        let displayed = store.displayedSeries(series)
        let explanation = SeriesExplanation(series: series, period: period,
            inverted: store.isExchangeRateInverted(series),
            formatNumber: { MarketFormat.number($0, digits: $1) })
        return VStack(alignment: .leading, spacing: focus ? Self.focusSectionSpacing : Self.sectionSpacing) {
            HStack(alignment: .top, spacing: Self.headerSpacing) {
                VStack(alignment: .leading, spacing: Self.titleSpacing) {
                    Text(MarketFormat.name(displayed))
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
            if focus {
                focusHeadline(displayed)
            } else {
                VStack(alignment: .leading, spacing: Self.valueSpacing) {
                    Text(displayed.latest.map { MarketFormat.number($0.value, digits: displayed.fractionDigits) } ?? "—")
                        .font(Self.valueFont).tracking(Self.valueTracking).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(Self.valueMinimumScale)
                    Text(MarketFormat.unit(displayed)).font(.callout).foregroundStyle(.secondary)
                    if series.latest != nil {
                        Text(MarketFormat.change(displayed, period: period) + " sur " + period.title)
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            if let explanation, focus || explanation.reading != nil || explanation.implication != nil {
                DisclosureGroup("Comprendre", isExpanded: $showsExplanation) {
                    SeriesExplanationView(explanation: explanation)
                }
                .font(.callout).fixedSize(horizontal: false, vertical: true)
            }
            if !focus { periodPicker }
            HistoryChart(series: displayed, period: period, height: focus ? nil : preview ? Self.previewChartHeight : Self.chartHeight, showsReading: !focus)
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
                        Text((series.isDemo ? "données fictives · " : "") + compactObservationPeriod)
                    } else { Label(observationPeriod, systemImage: "calendar") }
                }
                .font(.subheadline).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: SemaTheme.minorSpacing)
                if !focus { alertButton }
            }
            if !focus, store.isExchangeRateInverted(series), let pair = series.exchangeRatePair {
                Text("Lecture inversée calculée à partir de la série publiée. Les alertes restent exprimées en " + pair.publishedDescription + ".")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if !series.canAlert {
                Text("Alertes indisponibles pour cette unité.")
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
        .disclosureGroupStyle(RowDisclosureStyle())
        .onChange(of: series.id, initial: true) { _, _ in
            period = series.supports(.year) ? .year : .all
            showsExplanation = false
        }
    }

    private func focusHeadline(_ displayed: MarketSeries) -> some View {
        HStack(spacing: SemaTheme.majorSpacing) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: SemaTheme.majorSpacing) {
                    focusValue(displayed)
                    focusActions(displayed)
                }
                VStack(alignment: .leading, spacing: SemaTheme.minorSpacing) {
                    focusValue(displayed)
                    focusActions(displayed)
                }
            }
            Spacer(minLength: SemaTheme.minorSpacing)
            ExchangeDirectionButton(series: series)
            FavoriteButton(seriesID: series.id, seriesName: MarketFormat.name(displayed))
        }
    }

    private func focusActions(_ displayed: MarketSeries) -> some View {
        VStack(alignment: .leading, spacing: SemaTheme.minorSpacing) {
            variationBadge(displayed)
            alertButton
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder private var alertButton: some View {
        if store.isFollowing(series.id) {
            Button {
                store.prepareAlert(for: series)
            } label: { Label("Créer une alerte", systemImage: "bell.badge") }
            .buttonStyle(.bordered).controlSize(.small)
            .buttonBorderShape(.capsule)
            .font(.callout).tint(store.palette.accent)
            .disabled(!series.canAlert || !store.isSourceEnabled(for: series.id))
        }
    }

    private func focusValue(_ displayed: MarketSeries) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SemaTheme.minorSpacing) {
            Text(displayed.latest.map { MarketFormat.number($0.value, digits: displayed.fractionDigits) } ?? "—")
                .font(Self.focusValueFont).tracking(Self.focusValueTracking).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(Self.valueMinimumScale)
            Text(MarketFormat.unit(displayed)).font(.title).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func variationBadge(_ displayed: MarketSeries) -> some View {
        if displayed.change(for: period) != nil {
            Text(MarketFormat.change(displayed, period: period) + " sur " + period.title)
                .font(.callout.weight(.medium)).monospacedDigit().lineLimit(1)
                .foregroundStyle(store.palette.accent)
                .padding(.horizontal, SemaTheme.minorSpacing)
                .padding(.vertical, SemaTheme.badgeVerticalInset)
                .background(store.palette.accent.opacity(SemaTheme.badgeFillOpacity), in: Capsule())
        } else if series.latest != nil {
            Text(MarketFormat.change(displayed, period: period))
                .font(.callout).foregroundStyle(.secondary)
        }
    }

    private var sourceDetails: some View {
        VStack(alignment: .leading, spacing: Self.sourceSpacing) {
            if MarketFormat.name(series) != series.name {
                LabeledContent("Libellé officiel", value: series.name).textSelection(.enabled)
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
        guard let latest = series.latest else { return "Source et définition" }
        if let end = latest.periodEnd, end != latest.date {
            return "Période du " + MarketFormat.date(latest.date) + " au " + MarketFormat.date(end)
        }
        return "Donnée du " + MarketFormat.date(latest.date)
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
