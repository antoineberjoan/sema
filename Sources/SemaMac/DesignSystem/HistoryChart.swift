// Dessine l’historique et permet de lire l’observation originale au survol du graphique.
import SwiftUI
import Charts
import MarketCore

struct HistoryChart: View {
    static let defaultHeight: CGFloat = 190
    /// Beyond this many points, the line keeps one point per bucket so that drawing stays fluid.
    private static let decimationThreshold = 1_200
    private static let decimationTarget = 500
    /// Vertical margin around the curve: a share of its range, with floors for flat or near-zero series.
    private static let domainMargin = 0.2
    private static let relativeMarginFloor = 0.002
    private static let marginFloor = 0.0001
    private static let minimumAxisDigits = 4
    private static let maximumAxisDigits = 6
    private static let axisTickCount = 3
    private static let plotPadding: CGFloat = 12
    private static let pointSize: CGFloat = 35
    private static let contentSpacing: CGFloat = 9
    private static let readingSpacing: CGFloat = 3
    private static let readingHorizontalPadding: CGFloat = 10
    private static let readingVerticalPadding: CGFloat = 7
    private static let areaOpacity = 0.09
    private static let ruleOpacity = 0.35
    private static let lineWidth: CGFloat = 2
    private static let tooltipCorner: CGFloat = 8
    @Environment(\.semaAccent) private var accent
    let series: MarketSeries
    let period: HistoryPeriod
    var height: CGFloat? = Self.defaultHeight
    var showsReading = true
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
        let padding = max((high - low) * Self.domainMargin, abs(high) * Self.relativeMarginFloor, Self.marginFloor)
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
        VStack(alignment: .leading, spacing: Self.contentSpacing) {
            Chart {
                ForEach(drawnPoints) { point in
                    AreaMark(x: .value("Date", point.date), yStart: .value("Base", domain.lowerBound),
                             yEnd: .value(series.displayUnit, MarketFormat.double(point.value)))
                        .foregroundStyle(LinearGradient(colors: [accent.opacity(Self.areaOpacity), .clear], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Date", point.date), y: .value(series.displayUnit, MarketFormat.double(point.value)))
                        .foregroundStyle(accent).lineStyle(StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round, lineJoin: .round))
                }
                if let hovered {
                    RuleMark(x: .value("Date sélectionnée", hovered.date))
                        .foregroundStyle(Color.secondary.opacity(Self.ruleOpacity))
                    PointMark(x: .value("Date", hovered.date), y: .value(series.displayUnit, MarketFormat.double(hovered.value)))
                        .foregroundStyle(accent).symbolSize(Self.pointSize)
                        .annotation(position: .top, spacing: Theme.minorSpacing,
                                    overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                            VStack(alignment: .leading, spacing: Self.readingSpacing) {
                                Text(MarketFormat.date(hovered.date)).foregroundStyle(.secondary)
                                Text(MarketFormat.number(hovered.value, digits: series.fractionDigits) + " " + series.displayUnit)
                                    .fontWeight(.medium).monospacedDigit()
                            }
                            .font(.subheadline)
                            .padding(.horizontal, Self.readingHorizontalPadding).padding(.vertical, Self.readingVerticalPadding)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Self.tooltipCorner))
                            .modifier(Elevation())
                            .allowsHitTesting(false)
                        }
                }
            }
            .chartYScale(domain: domain)
            .chartXScale(range: .plotDimension(padding: Self.plotPadding))
            .chartXSelection(value: $hoveredDate)
            .contentShape(Rectangle())
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: Self.axisTickCount)) { _ in
                    AxisValueLabel(format: period.days > HistoryPeriod.year.days
                        ? .dateTime.month(.abbreviated).year()
                        : .dateTime.day().month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: Self.axisTickCount)) { value in
                    AxisGridLine().foregroundStyle(Theme.separator)
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(MarketFormat.number(Decimal(number), digits: axisDigits))
                        }
                    }
                }
            }
            .frame(minHeight: height ?? Self.defaultHeight, maxHeight: height ?? .infinity)
            .accessibilityLabel("Historique de \(series.name), en \(series.displayUnit)")

            if showsReading {
            HStack {
                Text(MarketFormat.date(hovered?.date ?? series.latest?.date))
                Spacer()
                if let value = hovered?.value ?? series.latest?.value {
                    Text(MarketFormat.number(value, digits: series.fractionDigits) + " " + series.displayUnit).monospacedDigit()
                }
            }
            .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .onChange(of: series.id) { _, _ in hoveredDate = nil }
        .onChange(of: series.unit) { _, _ in hoveredDate = nil }
        .onChange(of: period) { _, _ in hoveredDate = nil }
    }
}
