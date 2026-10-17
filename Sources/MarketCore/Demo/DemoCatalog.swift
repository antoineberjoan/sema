// Fournit les séries fictives identifiées pour explorer l’app sans connexion.
import Foundation

/// Fixed fixtures. No value in this catalog is presented as a current market quote.
public enum DemoCatalog {
    public static let observationDate = Date(timeIntervalSince1970: 1_792_022_400) // 2026-10-15 UTC

    public static func series() -> [MarketSeries] {
        [
            make("fr10", "Emprunt phare FR · 10 ans", "Rendement · série mensuelle", .markets, .percent, "3.42", 2, seed: 2, trend: -0.04),
            make("ecb", "Taux de dépôt BCE", "Politique monétaire", .savings, .percent, "2.00", 2, seed: 3, trend: 0, flat: true),
            make("eurusd", "Euro / Dollar", "USD pour 1 EUR", .markets, .usd, "1.1642", 4, seed: 4, trend: 0.04),
            make("eurjpy", "Euro / Yen", "JPY pour 1 EUR", .markets, .jpy, "171.46", 2, seed: 5, trend: 0.03),
            make("eurchf", "Euro / Franc suisse", "CHF pour 1 EUR", .markets, .chf, "0.9341", 4, seed: 6, trend: -0.02),
            make("livreta", "Livret A", "Épargne réglementée", .savings, .percent, "1.70", 2, seed: 7, trend: 0, flat: true),
            make("lep", "LEP", "Épargne réglementée", .savings, .percent, "2.70", 2, seed: 8, trend: 0, flat: true),
            make("inflation", "Inflation · France", "Glissement annuel", .savings, .percent, "1.20", 1, seed: 9, trend: -0.05),
            make("atlas-i-eur", "Atlas Monde", "Part I · EUR · Actions internationales", .funds, .eur, "174.62", 2, seed: 11, trend: 0.12),
            make("horizon-r-eur", "Horizon Patrimoine", "Part R · EUR · Allocation flexible", .funds, .eur, "128.45", 2, seed: 13, trend: 0.06),
            make("aster-c-eur", "Aster Europe", "Part C · EUR · Actions européennes", .funds, .eur, "246.18", 2, seed: 17, trend: 0.08),
            make("latitude-i-eur", "Latitude Obligations", "Part I · EUR · Obligations euro", .funds, .eur, "103.87", 2, seed: 19, trend: 0.025)
        ]
    }

    private static func make(
        _ id: String, _ name: String, _ subtitle: String, _ category: SeriesCategory,
        _ unit: ValueUnit, _ value: String, _ digits: Int,
        seed: Double, trend: Double, flat: Bool = false
    ) -> MarketSeries {
        let final = Decimal(string: value, locale: .posix)!
        let finalDouble = NSDecimalNumber(decimal: final).doubleValue
        let calendar = Calendar(identifier: .gregorian)
        let candidates = (0...365).map { day in
            observationDate.addingTimeInterval(-Double(365 - day) * .day)
        }.filter { !calendar.isDateInWeekend($0) }
        let points = candidates.enumerated().map { index, date in
            let t = Double(index) / Double(candidates.count - 1)
            let wave = (sin(Double(index) * 0.71 + seed) * 0.55 + sin(Double(index) * 1.63) * 0.25) * sin(.pi * t)
            let v = flat ? finalDouble : finalDouble / (1 + trend * (1 - t)) + finalDouble * 0.003 * wave
            let decimal = index == candidates.count - 1 ? final : Decimal(v)
            return MarketObservation(date: date, value: decimal)
        }
        return MarketSeries(id: id, name: name, subtitle: subtitle, category: category,
                            unit: unit, fractionDigits: digits, source: "Démonstration",
                            isDemo: true, observations: points)
    }
}
