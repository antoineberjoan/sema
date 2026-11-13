// Formate nombres, valeurs, variations et dates à la française pour l’affichage.
import AppKit
import MarketCore

enum MarketFormat {
    /// Les variations s’affichent toujours avec deux décimales, quelle que soit la précision de la série.
    static let changeDigits = 2
    static func number(_ value: Decimal, digits: Int = MarketSeries.defaultFractionDigits, signed: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .french
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        let formatted = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "—"
        return signed && value > 0 ? "+" + formatted : formatted
    }

    static func name(_ series: MarketSeries) -> String {
        series.exchangeRatePair?.publishedName ?? series.name
    }

    static func unit(_ series: MarketSeries) -> String {
        series.exchangeRatePair?.currency ?? series.displayUnit
    }

    static func value(_ series: MarketSeries) -> String {
        guard let value = series.latest?.value else { return "—" }
        let n = number(value, digits: series.fractionDigits)
        let label = unit(series)
        return n + (label.isEmpty ? "" : " " + label)
    }

    static func change(_ series: MarketSeries, period: HistoryPeriod) -> String {
        guard let delta = series.change(for: period) else { return series.variationConvention == .unavailable ? "Variation non calculée" : "Historique insuffisant" }
        return number(delta, digits: Self.changeDigits, signed: true) + (series.unit == .percent ? " pt" : " %")
    }

    /// Variation d’une séance : en points pour les taux, en pourcent sinon.
    static func sessionChange(_ change: Decimal, series: MarketSeries) -> String {
        number(change, digits: Self.changeDigits, signed: true) + (series.unit == .percent ? " pt" : " %")
    }

    /// Multiple de la variation habituelle, par exemple « 4,0× ».
    static func ratio(_ ratio: Double) -> String { number(Decimal(ratio), digits: 1) + "×" }

    static func date(_ date: Date?) -> String {
        guard let date else { return "Date inconnue" }
        return date.formatted(.dateTime.day().month(.abbreviated).year().locale(.french))
    }

    static func double(_ value: Decimal) -> Double { NSDecimalNumber(decimal: value).doubleValue }
}
