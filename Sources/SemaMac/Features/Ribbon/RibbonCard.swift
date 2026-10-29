// Carte d’un favori dans le bandeau : valeur, variation, courbe et date.
import SwiftUI
import Charts
import MarketCore

struct RibbonCard: View {
    private static let contentSpacing: CGFloat = 9
    private static let headingSpacing: CGFloat = 10
    private static let valueTracking: CGFloat = -0.9
    private static let valueMinimumScale: CGFloat = 0.7
    private static let unitLines = 2
    private static let headingLines = 2
    private static let sparklineHeight: CGFloat = 45
    @Environment(\.semaAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false
    let series: MarketSeries
    let period: HistoryPeriod
    let action: () -> Void
    private var points: [MarketObservation] { series.history(for: period) }
    private var comparison: String {
        series.supports(period) ? MarketFormat.change(series, period: period) : "Historique partiel"
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Self.contentSpacing) {
                heading
                value
                sparkline
                publication
            }
            .foregroundStyle(.primary).padding(MenuRibbonLayout.cardPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .modifier(RibbonSurface(emphasized: hovered))
            .contentShape(RoundedRectangle(cornerRadius: Theme.surfaceCorner))
        }
        .buttonStyle(PressStyle())
        .onHover { hovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: MenuRibbonLayout.hoverDuration), value: hovered)
        .help(MarketFormat.name(series) + " · Ouvrir le détail dans sema")
        .accessibilityLabel(accessibilityDescription)
    }

    private var heading: some View {
        HStack(spacing: Self.headingSpacing) {
            Text(MarketFormat.name(series)).font(.body.weight(.medium)).lineLimit(Self.headingLines)
            Spacer(minLength: 0)
        }
    }
    private var value: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.minorSpacing) {
            Text(series.latest.map { MarketFormat.number($0.value, digits: series.fractionDigits) } ?? "—")
                .font(MenuRibbonLayout.valueFont).tracking(Self.valueTracking).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(Self.valueMinimumScale)
            Text(MarketFormat.unit(series)).font(.subheadline).foregroundStyle(.secondary).lineLimit(Self.unitLines)
            Spacer(minLength: 0)
        }
    }
    @ViewBuilder private var sparkline: some View {
        if points.count > 1 {
            Chart(points) { point in
                LineMark(x: .value("Date", point.date), y: .value(series.displayUnit, MarketFormat.double(point.value)))
                    .foregroundStyle(accent)
                    .lineStyle(StrokeStyle(lineWidth: MenuRibbonLayout.sparklineWidth, lineCap: .round, lineJoin: .round))
            }
            .chartXAxis(.hidden).chartYAxis(.hidden)
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: Self.sparklineHeight).accessibilityHidden(true)
        } else {
            Text(points.isEmpty ? "Historique indisponible" : "Une observation disponible")
                .font(.subheadline).foregroundStyle(.tertiary).frame(height: Self.sparklineHeight)
        }
    }
    private var publication: some View {
        HStack(spacing: Theme.minorSpacing) {
            Text(comparison).lineLimit(1)
            Spacer(minLength: 0)
            Text(series.latest.map { MarketFormat.date($0.date) } ?? "Aucune publication").lineLimit(1)
        }
        .font(.subheadline).monospacedDigit().foregroundStyle(.secondary)
    }
    private var accessibilityDescription: String {
        let name = MarketFormat.name(series)
        let value = MarketFormat.value(series)
        let date = MarketFormat.date(series.latest?.date)
        return "\(name), \(value), \(comparison) sur \(period.title), publication du \(date)"
    }
}
