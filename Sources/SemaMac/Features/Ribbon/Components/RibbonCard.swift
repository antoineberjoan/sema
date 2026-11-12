// Carte d’un favori dans le bandeau : nom et source, variation de la période, valeur, séance et courbe pleine largeur avec lecture au survol.
import SemaDesign
import SwiftUI
import Charts
import MarketCore

struct RibbonCard: View {
    private static let contentSpacing = DesignSpace.rowInset
    private static let valueMinimumScale: CGFloat = 0.7
    private static let headingLines = 2
    private static let chartHeight: CGFloat = 80
    private static let areaOpacity = 0.14
    private static let selectionPointSize: CGFloat = 36
    @Environment(AppStore.self) private var store
    @Environment(\.palette) private var palette
    private var accent: Color { DesignColor.accent(palette) }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    @State private var selectedDate: Date?
    let series: MarketSeries
    let period: HistoryPeriod
    let action: () -> Void
    private var points: [MarketObservation] { series.history(for: period) }
    private var comparison: String {
        series.supports(period) ? MarketFormat.change(series, period: period) : "Historique partiel"
    }
    /// The point under the pointer, if any.
    private var selected: MarketObservation? {
        guard let selectedDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }
    /// Last session, shown only when it left the usual range chosen in Réglages.
    private var unusual: UnusualMove? {
        UnusualMove(series: series).flatMap { $0.ratio >= store.moveSensitivity.multiplier ? $0 : nil }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: Self.contentSpacing) {
                    heading
                    valueAndDate
                }
                .padding([.top, .horizontal], MenuRibbonLayout.cardPadding)
                Spacer(minLength: Self.contentSpacing)
                chart
            }
            .foregroundStyle(DesignColor.text)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card))
            .modifier(RibbonSurface(isEmphasized: isHovered))
            .contentShape(RoundedRectangle(cornerRadius: DesignRadius.card))
        }
        .buttonStyle(PressStyle())
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .timingCurve(DesignEase.hover, duration: MenuRibbonLayout.hoverDuration), value: isHovered)
        .contextMenu {
            Button(store.isWatched(series.id) ? "Ne plus surveiller les mouvements" : "Me prévenir des mouvements inhabituels") {
                Task { await store.toggleWatch(series) }
            }.disabled(!store.canWatch(series))
        }
        .help(MarketFormat.name(series) + " · Ouvrir le détail dans sema")
        .accessibilityLabel(accessibilityDescription)
    }

    private var heading: some View {
        HStack(alignment: .top, spacing: DesignSpace.fieldGap) {
            VStack(alignment: .leading, spacing: 0) {
                Text(MarketFormat.name(series)).typeRole(.heading).lineLimit(Self.headingLines)
                Text(series.originBadge + " · " + MarketFormat.unit(series)).typeRole(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(series.supports(period) ? comparison + " · " + period.shortTitle : comparison)
                .typeRole(.tag).monospacedDigit().lineLimit(1)
                .padding(.horizontal, DesignSpace.markInsetInline).padding(.vertical, DesignSpace.markInset)
                .background(DesignColor.text.opacity(DesignOpacity.glassRest), in: RoundedRectangle(cornerRadius: DesignRadius.mark))
        }
    }

    private var valueAndDate: some View {
        VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
            Text((selected ?? series.latest).map { MarketFormat.number($0.value, digits: series.fractionDigits) } ?? "—")
                .typeRole(.figure).lineLimit(1).minimumScaleFactor(Self.valueMinimumScale)
            HStack(spacing: DesignSpace.fieldGap) {
                Text((selected ?? series.latest).map { MarketFormat.date($0.date) } ?? "Aucune publication").lineLimit(1)
                if selected == nil, let unusual {
                    MoveBadge(ratio: unusual.ratio, prefix: MarketFormat.sessionChange(unusual.change, series: series) + " · ")
                }
            }
            .typeRole(.caption).monospacedDigit().foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var chart: some View {
        if points.count > 1 {
            Chart {
                ForEach(points) { point in
                    AreaMark(x: .value("Date", point.date), y: .value(series.displayUnit, MarketFormat.double(point.value)))
                        .foregroundStyle(accent.opacity(Self.areaOpacity))
                    LineMark(x: .value("Date", point.date), y: .value(series.displayUnit, MarketFormat.double(point.value)))
                        .foregroundStyle(accent)
                        .lineStyle(StrokeStyle(lineWidth: MenuRibbonLayout.sparklineWidth, lineCap: .round, lineJoin: .round))
                }
                if let selected {
                    RuleMark(x: .value("Date", selected.date))
                        .foregroundStyle(.secondary).lineStyle(StrokeStyle(lineWidth: DesignBorder.width, dash: [2, 3]))
                    PointMark(x: .value("Date", selected.date), y: .value(series.displayUnit, MarketFormat.double(selected.value)))
                        .symbolSize(Self.selectionPointSize).foregroundStyle(accent)
                }
            }
            .chartXSelection(value: $selectedDate)
            .chartXAxis(.hidden).chartYAxis(.hidden)
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: Self.chartHeight).accessibilityHidden(true)
        } else {
            Text(points.isEmpty ? "Historique indisponible" : "Une observation disponible")
                .typeRole(.caption).foregroundStyle(.secondary)
                .padding(.horizontal, MenuRibbonLayout.cardPadding).padding(.bottom, MenuRibbonLayout.cardPadding)
                .frame(height: Self.chartHeight, alignment: .bottomLeading)
        }
    }

    private var accessibilityDescription: String {
        let name = MarketFormat.name(series)
        let value = MarketFormat.value(series)
        let date = MarketFormat.date(series.latest?.date)
        let session = unusual.map { ", séance \(MarketFormat.sessionChange($0.change, series: series)), \(MarketFormat.ratio($0.ratio)) la variation habituelle" } ?? ""
        return "\(name), \(value), \(comparison) sur \(period.title), publication du \(date)\(session)"
    }
}
