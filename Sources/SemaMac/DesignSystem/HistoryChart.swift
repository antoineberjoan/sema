import SwiftUI
import Charts
import MarketCore

struct HistoryChart: View {
    let series: MarketSeries
    let period: HistoryPeriod
    var height: CGFloat = 190
    @State private var hoveredDate: Date?

    private var points: [MarketObservation] { series.history(for: period) }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Chart {
                ForEach(points) { point in
                    AreaMark(x: .value("Date", point.date), yStart: .value("Base", domain.lowerBound),
                             yEnd: .value(series.unit.symbol, MarketFormat.double(point.value)))
                        .foregroundStyle(LinearGradient(colors: [SemaTheme.accent.opacity(0.09), .clear], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Date", point.date), y: .value(series.unit.symbol, MarketFormat.double(point.value)))
                        .foregroundStyle(SemaTheme.accent).lineStyle(StrokeStyle(lineWidth: 1.8))
                }
                if let hovered {
                    RuleMark(x: .value("Date sélectionnée", hovered.date))
                        .foregroundStyle(Color.secondary.opacity(0.35))
                    PointMark(x: .value("Date", hovered.date), y: .value(series.unit.symbol, MarketFormat.double(hovered.value)))
                        .foregroundStyle(SemaTheme.accent).symbolSize(35)
                        .annotation(position: .top, spacing: 8,
                                    overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(MarketFormat.date(hovered.date)).foregroundStyle(.secondary)
                                Text(MarketFormat.number(hovered.value, digits: series.fractionDigits) + " " + series.unit.symbol)
                                    .fontWeight(.medium).monospacedDigit()
                            }
                            .font(.system(size: 11))
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(SemaTheme.separator, lineWidth: 0.5))
                            .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
                            .allowsHitTesting(false)
                        }
                }
            }
            .chartYScale(domain: domain)
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
                            Text(MarketFormat.number(Decimal(number), digits: min(series.fractionDigits, 3)))
                        }
                    }
                }
            }
            .frame(height: height)
            .accessibilityLabel("Historique de \(series.name), en \(series.unit.symbol)")

            HStack {
                Text(MarketFormat.date(hovered?.date ?? series.latest?.date))
                Spacer()
                if let value = hovered?.value ?? series.latest?.value {
                    Text(MarketFormat.number(value, digits: series.fractionDigits) + " " + series.unit.symbol).monospacedDigit()
                }
            }
            .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .onChange(of: series.id) { _, _ in hoveredDate = nil }
        .onChange(of: period) { _, _ in hoveredDate = nil }
    }
}

struct Sparkline: View {
    let series: MarketSeries
    private var values: [MarketObservation] { series.history(for: .month) }
    var body: some View {
        Chart(values) { point in
            LineMark(x: .value("Date", point.date), y: .value("Valeur", MarketFormat.double(point.value)))
                .foregroundStyle(SemaTheme.accent.opacity(0.8)).lineStyle(StrokeStyle(lineWidth: 1.4))
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis(.hidden).chartYAxis(.hidden)
        .frame(width: 68, height: 28)
        .accessibilityHidden(true)
    }
}
