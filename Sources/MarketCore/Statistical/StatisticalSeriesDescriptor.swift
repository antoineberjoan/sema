// Série choisie dans un jeu : clé, dimensions et métadonnées officielles.
import Foundation

public struct StatisticalSeriesDescriptor: Codable, Equatable, Sendable {
    public let dataset: StatisticalDataset
    public let key: String
    public let dimensionIDs: [String]
    public let fields: [String: String]
    public let labels: [String: String]
    public var id: String { "\(dataset.id):\(key)" }
    public var title: String { fields["TITLE_FR"] ?? fields["TITLE"] ?? fields["TITLE_EN"] ?? dataset.title }
    public var definition: String { fields["TITLE_COMPL"] ?? dataset.detail }
    public var unitCode: String? { fields["UNIT_MEASURE"] ?? fields["UNIT"] }
    public var multiplier: Int? {
        if let value = fields["UNIT_MULT"].flatMap(Int.init) { return value }
        // Eurostat includes scale in its UNIT code (e.g. MIO_EUR). The values are
        // already expressed in that labelled unit, with no separate UNIT_MULT.
        if dataset.source == .eurostat, fields["UNIT"] != nil, labels["UNIT"] != nil { return 0 }
        return nil
    }
    public var unit: ValueUnit {
        switch unitCode {
        case "PC", "PCPA", "PCT", "PCPT", "PCCH", "PT", "PD", "POURCENT", "RCH_A", "RCH_M": .percent
        case "USD": .usd; case "JPY": .jpy; case "CHF": .chf; case "GBP": .gbp; case "EUR": .eur
        case "IX", "INX", "IDX": .index
        case "SO" where fields["NATURE"] == "INDICE" || title.localizedCaseInsensitiveContains("indice"): .index
        case "NUMBER", "UNITS", "PN": .number
        default: .unknown
        }
    }
    public var displayUnit: String {
        let label = unitCode == "SO" && unit == .index ? "indice"
            : labels["UNIT_MEASURE"] ?? labels["UNIT"] ?? (unit == .unknown ? unitCode ?? "Unité non renseignée" : unit.symbol)
        guard let multiplier, multiplier != 0 else { return label }
        return "\(label) · × 10^\(multiplier)"
    }
    public var frequency: ObservationFrequency {
        switch fields["FREQ"] {
        case "D": .daily; case "B": .businessDaily; case "W": .weekly; case "M": .monthly
        case "Q", "T": .quarterly; case "H", "S": .halfYearly; case "A", "Y": .yearly
        default: .unknown
        }
    }
    public var canAlert: Bool {
        if unitCode == "SO" && unit == .unknown { return false }
        return multiplier != nil && !["_Z", "_X"].contains(unitCode ?? "") && (unit != .unknown || labels["UNIT_MEASURE"] != nil || labels["UNIT"] != nil)
    }
    public var variation: VariationConvention {
        if unit == .percent && multiplier == 0 { return .points }
        if dataset.source == .ecb && dataset.code == "EXR" && multiplier == 0 && [.usd, .jpy, .chf, .gbp].contains(unit) { return .relativePercent }
        return .unavailable
    }
    public func usesSameMeasurement(as other: StatisticalSeriesDescriptor) -> Bool {
        unitCode == other.unitCode && multiplier == other.multiplier && fields["UNIT_INDEX_BASE"] == other.fields["UNIT_INDEX_BASE"] && fields["BASIND"] == other.fields["BASIND"]
    }
    public func series(observations: [MarketObservation], syncedAt: Date? = nil, completeHistory: Bool = false) -> MarketSeries {
        MarketSeries(id: id, name: title,
            subtitle: [labels["REF_AREA"] ?? fields["REF_AREA"] ?? labels["GEO"] ?? fields["GEO"], frequency.title].compactMap { $0 }.joined(separator: " · "),
            category: .markets, unit: unit, fractionDigits: min(max(Int(fields["DECIMALS"] ?? "") ?? MarketSeries.defaultFractionDigits, 0), MarketSeries.maximumFractionDigits),
            source: dataset.source.title, sourceURL: sourceURL, isDemo: false, frequency: frequency,
            observations: observations, syncedAt: syncedAt, hasCompleteHistory: completeHistory, statisticalDescriptor: self)
    }
    public var sourceURL: URL {
        if dataset.source == .insee, let idbank = fields["IDBANK"], idbank.allSatisfy(\.isNumber) {
            return URL(string: "https://www.insee.fr/fr/statistiques/serie/\(idbank)")!
        }
        return dataset.source.website
    }
}
