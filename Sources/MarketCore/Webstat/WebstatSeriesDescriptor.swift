// Métadonnées d’une série Webstat et leur traduction en série affichable.
import Foundation

public struct WebstatSeriesDescriptor: Codable, Equatable, Sendable, Identifiable {
    static let maximumKeyLength = 300
    public var id: String { key }
    public let key: String
    public let datasetID: String
    public let title: String
    public let definition: String
    public let producer: String
    public let area: String?
    public let frequencyCode: String?
    public let unitCode: String?
    public let multiplier: Int?
    public let decimals: Int?
    public let currency: String?
    public let firstPeriod: Date?
    public let lastPeriod: Date?
    public let raw: [String: WebstatValue]
    public let labels: [String: String]

    public init(raw: [String: WebstatValue], labels: [String: String] = [:]) throws {
        let dimensions = Self.dictionary(raw["series_dimensions_and_values"]?.text)
        let attributes = Self.dictionary(raw["series_attributes_and_values"]?.text)
        func text(_ field: String) -> String? {
            (raw[field]?.text ?? attributes[field.uppercased()] ?? dimensions[field.uppercased()]).flatMap { $0.isEmpty ? nil : $0 }
        }
        guard let key = text("series_key"), Self.isValidKey(key) else { throw WebstatClient.ClientError.invalidData }
        self.key = key
        datasetID = text("dataset_id") ?? String(key.split(separator: ".").first ?? "")
        title = text("title_fr") ?? text("title_en") ?? key
        definition = text("title_long_fr") ?? text("title_long_en") ?? title
        producer = labels["source_agency"] ?? text("source_agency") ?? "Producteur non renseigné"
        area = labels["ref_area"] ?? text("ref_area") ?? dimensions["REF_AREA"] ?? dimensions["AME_REF_AREA"] ?? dimensions["ZONE_GEO"]
        frequencyCode = text("freq")
        unitCode = text("unit")
        multiplier = text("unit_mult").flatMap(Int.init)
        decimals = text("decimals").flatMap(Int.init).map { min(max($0, 0), MarketSeries.maximumFractionDigits) }
        currency = text("currency") ?? dimensions["CURRENCY"] ?? dimensions["CURRENCY_TRANS"]
        firstPeriod = Self.date(text("first_time_period_date"))
        lastPeriod = Self.date(text("last_time_period_date"))
        self.raw = raw
        self.labels = labels
    }

    public func resolving(labels: [String: String]) -> WebstatSeriesDescriptor {
        // The key was validated at construction and raw values remain unchanged.
        (try? WebstatSeriesDescriptor(raw: raw, labels: self.labels.merging(labels, uniquingKeysWith: { _, new in new }))) ?? self
    }

    public var frequency: ObservationFrequency {
        switch frequencyCode {
        case "D": .daily
        case "B": .businessDaily
        case "W": .weekly
        case "M": .monthly
        case "Q": .quarterly
        case "H", "S": .halfYearly
        case "A", "Y": .yearly
        default: .unknown
        }
    }
    public var frequencyTitle: String {
        if let label = labels["freq"] { return label }
        return frequency == .unknown ? "Fréquence : \(frequencyCode ?? "non renseignée")" : frequency.title
    }
    public var unit: ValueUnit {
        switch unitCode {
        case "PC", "PCPA", "PCT", "PCPT", "PCCH", "PT", "PD": .percent
        case "USD": .usd
        case "JPY": .jpy
        case "CHF": .chf
        case "GBP": .gbp
        case "EUR": .eur
        case "IX", "INX", "IDX": .index
        case "PN", "NUMBER", "UNITS": .number
        default: .unknown
        }
    }
    public var displayUnit: String {
        let base: String
        if let label = labels["unit"], !label.isEmpty { base = label }
        else if unit != .unknown { base = unit.symbol }
        else { base = "Unité \(unitCode ?? "non renseignée")" }
        guard let multiplier, multiplier != 0 else { return base }
        let scale: String
        if let label = labels["unit_mult"] { scale = label.lowercased() }
        else { switch multiplier { case 3: scale = "milliers"; case 6: scale = "millions"; case 9: scale = "milliards"; default: scale = "× 10^\(multiplier)" } }
        return base.isEmpty ? scale : "\(scale) · \(base)"
    }
    /// Thresholds use the source scale; obs_value is never multiplied a second time.
    public var canAlert: Bool { multiplier != nil && unitCode != "_Z" && unitCode != "_X" && (unit != .unknown || labels["unit"] != nil) }
    public var variation: VariationConvention {
        if unit == .percent, multiplier == 0 { return .points }
        if [.usd, .jpy, .chf, .gbp].contains(unit), multiplier == 0 { return .relativePercent }
        return .unavailable
    }
    /// Never splice values expressed in two scales or index bases into one curve.
    public func usesSameMeasurement(as other: WebstatSeriesDescriptor) -> Bool {
        unitCode == other.unitCode && multiplier == other.multiplier &&
        attributes["UNIT_INDEX_BASE"] == other.attributes["UNIT_INDEX_BASE"]
    }
    public var dimensions: [String: String] { Self.dictionary(raw["series_dimensions_and_values"]?.text) }
    public var attributes: [String: String] { Self.dictionary(raw["series_attributes_and_values"]?.text) }
    static func dictionary(_ text: String?) -> [String: String] {
        guard let data = text?.data(using: .utf8), let values = try? JSONDecoder().decode([String: WebstatValue].self, from: data) else { return [:] }
        return values.compactMapValues(\.text)
    }
    /// Catalogue bounds are end-of-period dates; exports filter the start of that period.
    public var firstObservationStart: Date? {
        guard let firstPeriod else { return nil }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let component: Calendar.Component
        switch frequency {
        case .monthly: component = .month
        case .quarterly: component = .quarter
        case .yearly: component = .year
        case .halfYearly:
            let parts = calendar.dateComponents([.year, .month], from: firstPeriod)
            return calendar.date(from: DateComponents(year: parts.year, month: (parts.month ?? 1) <= 6 ? 1 : 7, day: 1))
        default: return firstPeriod
        }
        return calendar.dateInterval(of: component, for: firstPeriod)?.start
    }
    public var sourceURL: URL {
        var url = URLComponents(); url.scheme = "https"; url.host = "webstat.banque-france.fr"
        url.path = "/fr/catalogue/\(datasetID.lowercased())/\(key)"
        return url.url!
    }
    public func series(observations: [MarketObservation], syncedAt: Date? = nil, completeHistory: Bool = false) -> MarketSeries {
        MarketSeries(id: key, name: title, subtitle: [area, frequencyTitle].compactMap { $0 }.joined(separator: " · "),
            category: .markets, unit: unit, fractionDigits: decimals ?? MarketSeries.defaultFractionDigits, source: producer,
            sourceURL: sourceURL, frequency: frequency, observations: observations,
            descriptor: self, syncedAt: syncedAt, hasCompleteHistory: completeHistory)
    }
    public static func isValidKey(_ key: String) -> Bool {
        key.count <= Self.maximumKeyLength && key.range(of: "^[A-Za-z0-9_][A-Za-z0-9_.-]*$", options: .regularExpression) != nil
    }
    static func date(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withFullDate]
        return formatter.date(from: String(value.prefix(10)))
    }
}
