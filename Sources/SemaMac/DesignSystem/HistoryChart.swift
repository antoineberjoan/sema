import SwiftUI
import Charts
import MarketCore

struct HistoryChart: View {
    @Environment(\.semaAccent) private var accent
    let series: MarketSeries
    let period: HistoryPeriod
    var height: CGFloat = 190
    @State private var hoveredDate: Date?

    private var points: [MarketObservation] { series.history(for: period) }
    // Drawing is bounded; hover and analysis always retain every original observation.
    private var drawnPoints: [MarketObservation] {
        guard points.count > 1_200 else { return points }
        let bucket = max(1, points.count / 500)
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
        let padding = max((high - low) * 0.2, abs(high) * 0.002, 0.0001)
        return (low - padding)...(high + padding)
    }
    private var hovered: MarketObservation? {
        guard let hoveredDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(hoveredDate)) < abs($1.date.timeIntervalSince(hoveredDate)) }
    }
    private var axisDigits: Int {
        let step = (domain.upperBound - domain.lowerBound) / 2
        let limit = max(4, min(series.fractionDigits, 6))
        return max(min(series.fractionDigits, limit), min(limit, max(0, Int(ceil(-log10(step))))))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Chart {
                ForEach(drawnPoints) { point in
                    AreaMark(x: .value("Date", point.date), yStart: .value("Base", domain.lowerBound),
                             yEnd: .value(series.displayUnit, MarketFormat.double(point.value)))
                        .foregroundStyle(LinearGradient(colors: [accent.opacity(0.09), .clear], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Date", point.date), y: .value(series.displayUnit, MarketFormat.double(point.value)))
                        .foregroundStyle(accent).lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
                if let hovered {
                    RuleMark(x: .value("Date sélectionnée", hovered.date))
                        .foregroundStyle(Color.secondary.opacity(0.35))
                    PointMark(x: .value("Date", hovered.date), y: .value(series.displayUnit, MarketFormat.double(hovered.value)))
                        .foregroundStyle(accent).symbolSize(35)
                        .annotation(position: .top, spacing: 8,
                                    overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(MarketFormat.date(hovered.date)).foregroundStyle(.secondary)
                                Text(MarketFormat.number(hovered.value, digits: series.fractionDigits) + " " + series.displayUnit)
                                    .fontWeight(.medium).monospacedDigit()
                            }
                            .font(.system(size: 11))
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                            .modifier(SemaElevation())
                            .allowsHitTesting(false)
                        }
                }
            }
            .chartYScale(domain: domain)
            .chartXScale(range: .plotDimension(padding: 12))
            .chartXSelection(value: $hoveredDate)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisValueLabel(format: period.days > 365
                        ? .dateTime.month(.abbreviated).year()
                        : .dateTime.day().month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine().foregroundStyle(SemaTheme.separator)
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(MarketFormat.number(Decimal(number), digits: axisDigits))
                        }
                    }
                }
            }
            .frame(height: height)
            .accessibilityLabel("Historique de \(series.name), en \(series.displayUnit)")

            HStack {
                Text(MarketFormat.date(hovered?.date ?? series.latest?.date))
                Spacer()
                if let value = hovered?.value ?? series.latest?.value {
                    Text(MarketFormat.number(value, digits: series.fractionDigits) + " " + series.displayUnit).monospacedDigit()
                }
            }
            .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .onChange(of: series.id) { _, _ in hoveredDate = nil }
        .onChange(of: series.unit) { _, _ in hoveredDate = nil }
        .onChange(of: period) { _, _ in hoveredDate = nil }
    }
}
