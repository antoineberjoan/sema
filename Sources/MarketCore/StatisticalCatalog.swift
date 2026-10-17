// Décrit les fournisseurs, jeux, dimensions et métadonnées nécessaires à la découverte des séries.
import Foundation

public enum StatisticalSource: String, Codable, CaseIterable, Sendable, Identifiable {
    case insee, ecb, eurostat, bis, oecd, newYorkFed, worldBank
    public var id: String { rawValue }
    public var title: String {
        switch self { case .insee: "Insee"; case .ecb: "BCE"; case .eurostat: "Eurostat"
        case .bis: "BRI"; case .oecd: "OCDE"; case .newYorkFed: "Fed de New York"; case .worldBank: "Banque mondiale" }
    }
    public var isSDMX: Bool { ![.newYorkFed, .worldBank].contains(self) }
    public var baseURL: String {
        switch self {
        case .insee: "https://bdm.insee.fr/series/sdmx"
        case .ecb: "https://data-api.ecb.europa.eu/service"
        case .eurostat: "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1"
        case .bis: "https://stats.bis.org/api/v2"
        case .oecd: "https://sdmx.oecd.org/public/rest/v1"
        case .newYorkFed: "https://markets.newyorkfed.org/api/rates"
        case .worldBank: "https://api.worldbank.org/v2"
        }
    }
    public var website: URL {
        let address = switch self {
        case .insee: "https://www.insee.fr/fr/statistiques"
        case .ecb: "https://data.ecb.europa.eu"
        case .eurostat: "https://ec.europa.eu/eurostat/databrowser"
        case .bis: "https://data.bis.org"
        case .oecd: "https://data-explorer.oecd.org"
        case .newYorkFed: "https://www.newyorkfed.org/markets/reference-rates"
        case .worldBank: "https://data.worldbank.org"
        }
        return URL(string: address)!
    }
    public var termsURL: URL {
        let address = switch self {
        case .insee: "https://www.insee.fr/fr/information/2008466"
        case .ecb: "https://www.ecb.europa.eu/stats/ecb_statistics/governance_and_quality_framework/html/usage_policy.en.html"
        case .eurostat: "https://ec.europa.eu/eurostat/help/copyright-notice"
        case .bis: "https://www.bis.org/about/legal/permitted-use-statistics"
        case .oecd: "https://www.oecd.org/en/about/terms-conditions.html"
        case .newYorkFed: "https://www.newyorkfed.org/privacy/termsofuse.html"
        case .worldBank: "https://data.worldbank.org/summary-terms-of-use"
        }
        return URL(string: address)!
    }
    public var scope: String {
        switch self {
        case .newYorkFed: "Taux de référence, moyennes, indices, percentiles et volumes publiés. Les opérations de marché ne sont pas des séries de taux et ne sont pas intégrées ici."
        case .worldBank: "Catalogue des indicateurs publics · choix du pays ou de l’agrégat."
        default: "Catalogue publié par la source · choisissez un jeu puis une combinaison de dimensions."
        }
    }
    public var attribution: String {
        switch self {
        case .insee: "Source : Insee. Licence Ouverte 2.0, sauf mention contraire."
        case .ecb: "Source : statistiques BCE. Les données de tiers restent soumises aux droits de leur producteur."
        case .eurostat: "Source : Eurostat. Les données de tiers et certaines données hors Europe ont des conditions de réutilisation spécifiques."
        case .bis: "Source : BRI. L’inclusion de ces statistiques dans un produit ne doit pas entraîner de supplément facturé à l’utilisateur."
        case .oecd: "Source : OCDE. Vérifier les restrictions propres au jeu et aux données de tiers."
        case .worldBank: "Source : Banque mondiale. CC BY 4.0, sauf restrictions indiquées pour les données de tiers."
        case .newYorkFed: "The reference rate data is subject to the Terms of Use posted at newyorkfed.org. The New York Fed is not responsible for publication of the reference rate data by Sema, does not endorse any particular republication, and has no liability for your use. Sema is not affiliated with the New York Fed. The New York Fed does not sanction, endorse, or recommend any products or services offered by Sema."
        }
    }
}

public struct StatisticalDataset: Codable, Equatable, Sendable, Identifiable {
    public let source: StatisticalSource
    public let code: String
    public let agency: String
    public let version: String
    public let title: String
    public let detail: String
    public let metadata: [String: String]
    public var id: String { "\(source.rawValue):\(agency):\(code):\(version)" }
    public init(source: StatisticalSource, code: String, agency: String, version: String,
                title: String, detail: String, metadata: [String: String] = [:]) {
        self.source = source; self.code = code; self.agency = agency; self.version = version
        self.title = title; self.detail = detail; self.metadata = metadata
    }
}

public struct StatisticalCode: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
}

public struct StatisticalDimension: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let position: Int
    public let codes: [StatisticalCode]
}

public struct StatisticalStructure: Codable, Equatable, Sendable {
    public let dimensions: [StatisticalDimension]
    public let labels: [String: [String: String]]
    public var missingCodelists: [StatisticalCodelistReference] = []
    public func key(values: [String: String]) -> String {
        dimensions.map { values[$0.id] ?? "" }.joined(separator: ".")
    }
}

public struct StatisticalCodelistReference: Codable, Hashable, Sendable {
    public let agency: String
    public let code: String
    public let version: String
}

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
            category: .markets, unit: unit, fractionDigits: min(max(Int(fields["DECIMALS"] ?? "") ?? 2, 0), 10),
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
