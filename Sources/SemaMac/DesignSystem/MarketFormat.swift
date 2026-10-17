// Formate nombres, valeurs, variations et dates à la française pour l’affichage.
import AppKit
import MarketCore

enum MarketFormat {
    /// Variations are always shown with two decimals, whatever the precision of the series.
    static let changeDigits = 2
    static func number(_ value: Decimal, digits: Int = MarketSeries.defaultFractionDigits, signed: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        let formatted = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "—"
        return signed && value > 0 ? "+" + formatted : formatted
    }

    static func value(_ series: MarketSeries) -> String {
        guard let value = series.latest?.value else { return "—" }
        let n = number(value, digits: series.fractionDigits)
        return n + (series.displayUnit.isEmpty ? "" : " " + series.displayUnit)
    }

    static func change(_ series: MarketSeries, period: HistoryPeriod) -> String {
        guard let delta = series.change(for: period) else { return series.variationConvention == .unavailable ? "Variation non calculée" : "Historique insuffisant" }
        return number(delta, digits: Self.changeDigits, signed: true) + (series.unit == .percent ? " pt" : " %")
    }

    static func date(_ date: Date?) -> String {
        guard let date else { return "Date inconnue" }
        return date.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "fr_FR")))
    }

    static func double(_ value: Decimal) -> Double { NSDecimalNumber(decimal: value).doubleValue }
}
