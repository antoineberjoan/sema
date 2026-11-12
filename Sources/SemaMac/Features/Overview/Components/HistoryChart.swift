// Dessine l’historique et permet de lire l’observation originale au survol du graphique.
// @documentation https://developer.apple.com/documentation/charts
// @decision docs/decisions/2026-11-12-composant-history-chart.md
import SemaDesign
import SwiftUI
import Charts
import MarketCore

struct HistoryChart: View {
    /// Beyond this many points, the line keeps one point per bucket so that drawing stays fluid.
    private static let decimationThreshold = 1_200
    private static let decimationTarget = 500
    private static let minimumAxisDigits = 4
    private static let maximumAxisDigits = 6
    @Environment(\.palette) private var palette
    private var accent: Color { DesignColor.accent(palette) }
    let series: MarketSeries
    let period: HistoryPeriod
    var height: CGFloat? = DesignLayout.historyChartDefaultHeight
    var isReadingShown = true
    @State private var hoveredDate: Date?

    private var points: [MarketObservation] { series.history(for: period) }
    // Drawing is bounded; hover and analysis always retain every original observation.
    private var drawnPoints: [MarketObservation] {
        guard points.count > Self.decimationThreshold else { return points }
        let bucket = max(1, points.count / Self.decimationTarget)
        var reduced: [MarketObservation] = []
        for start in stride(from: 0, to: points.count, by: bucket) {
            let slice = points[start..<min(start + bucket, points.count)]
            if let low = slice.min(by: { $0.value < $1.value }), let high = slice.max(by: { $0.value < $1.value }) {
                reduced += low.date == high.date ? [low] : [low, high].sorted { $0.date < $1.date }
            }
        }
        if let first = points.first, reduced.first?.date != first.date { reduced.insert(first, at: 0) }
        if let last = points.last, reduced.last?.date != last.date { reduced.append(last) }
        return reduced
    }
    private var domain: ClosedRange<Double> {
        let values = points.map { MarketFormat.double($0.value) }
        let low = values.min() ?? 0
        let high = values.max() ?? 1
        let padding = max((high - low) * DesignMeasure.historyChartDomainMargin, abs(high) * DesignMeasure.historyChartRelativeMarginFloor, DesignMeasure.historyChartMarginFloor)
        return (low - padding)...(high + padding)
    }
    private var hovered: MarketObservation? {
        guard let hoveredDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(hoveredDate)) < abs($1.date.timeIntervalSince(hoveredDate)) }
    }
    private var axisDigits: Int {
        let step = (domain.upperBound - domain.lowerBound) / 2
        let limit = max(Self.minimumAxisDigits, min(series.fractionDigits, Self.maximumAxisDigits))
        return max(min(series.fractionDigits, limit), min(limit, max(0, Int(ceil(-log10(step))))))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignLayout.historyChartContentSpacing) {
            Chart {
                ForEach(drawnPoints) { point in
                    AreaMark(x: .value("Date", point.date), yStart: .value("Base", domain.lowerBound),
                             yEnd: .value(series.displayUnit, MarketFormat.double(point.value)))
                        .foregroundStyle(LinearGradient(colors: [accent.opacity(DesignOpacity.historyChartAreaOpacity), .clear], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Date", point.date), y: .value(series.displayUnit, MarketFormat.double(point.value)))
                        .foregroundStyle(accent).lineStyle(StrokeStyle(lineWidth: DesignLayout.historyChartLineWidth, lineCap: .round, lineJoin: .round))
                }
                if let hovered {
                    RuleMark(x: .value("Date sélectionnée", hovered.date))
                        .foregroundStyle(DesignColor.ruleHover)
                    PointMark(x: .value("Date", hovered.date), y: .value(series.displayUnit, MarketFormat.double(hovered.value)))
                        .foregroundStyle(accent).symbolSize(DesignLayout.historyChartPointSize)
                        .annotation(position: .top, spacing: DesignIcon.gap,
                                    overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                            VStack(alignment: .leading, spacing: DesignLayout.historyChartReadingSpacing) {
                                Text(MarketFormat.date(hovered.date)).foregroundStyle(DesignColor.textMuted)
                                Text(MarketFormat.number(hovered.value, digits: series.fractionDigits) + " " + series.displayUnit)
                                    .fontWeight(.medium).monospacedDigit()
                            }
                            .typeRole(.caption)
                            .padding(.horizontal, DesignLayout.historyChartReadingHorizontalPadding).padding(.vertical, DesignLayout.historyChartReadingVerticalPadding)
                            .background(DesignColor.surfaceRaised, in: RoundedRectangle(cornerRadius: DesignRadius.block))
                            .elevation(DesignElevation.floating)
                            .allowsHitTesting(false)
                        }
                }
            }
            .chartYScale(domain: domain)
            .chartXScale(range: .plotDimension(padding: DesignLayout.historyChartPlotPadding))
            .chartXSelection(value: $hoveredDate)
            .contentShape(Rectangle())
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: DesignLayout.historyChartAxisTickCount)) { _ in
                    AxisValueLabel(format: period.days > HistoryPeriod.year.days
                        ? .dateTime.month(.abbreviated).year()
                        : .dateTime.day().month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: DesignLayout.historyChartAxisTickCount)) { value in
                    AxisGridLine().foregroundStyle(DesignColor.rule)
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(MarketFormat.number(Decimal(number), digits: axisDigits))
                        }
                    }
                }
            }
            .frame(minHeight: height ?? DesignLayout.historyChartDefaultHeight, maxHeight: height ?? .infinity)
            .accessibilityLabel("Historique de \(series.name), en \(series.displayUnit)")

            if isReadingShown {
            HStack {
                Text(MarketFormat.date(hovered?.date ?? series.latest?.date))
                Spacer()
                if let value = hovered?.value ?? series.latest?.value {
                    Text(MarketFormat.number(value, digits: series.fractionDigits) + " " + series.displayUnit).monospacedDigit()
                }
            }
            .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
        }
        .onChange(of: series.id) { _, _ in hoveredDate = nil }
        .onChange(of: series.unit) { _, _ in hoveredDate = nil }
        .onChange(of: period) { _, _ in hoveredDate = nil }
    }
}
