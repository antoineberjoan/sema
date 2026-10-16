import Foundation

/// Source values are kept verbatim, including fields that Sema does not interpret yet.
public enum WebstatValue: Codable, Equatable, Sendable {
    case string(String), number(Decimal), bool(Bool), array([WebstatValue]), object([String: WebstatValue]), null

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer()
        if value.decodeNil() { self = .null }
        else if let text = try? value.decode(String.self) { self = .string(text) }
        else if let boolean = try? value.decode(Bool.self) { self = .bool(boolean) }
        else if let number = try? value.decode(Decimal.self) { self = .number(number) }
        else if let array = try? value.decode([WebstatValue].self) { self = .array(array) }
        else { self = .object(try value.decode([String: WebstatValue].self)) }
    }
    public func encode(to encoder: any Encoder) throws {
        var value = encoder.singleValueContainer()
        switch self {
        case .string(let text): try value.encode(text)
        case .number(let number): try value.encode(number)
        case .bool(let boolean): try value.encode(boolean)
        case .array(let array): try value.encode(array)
        case .object(let object): try value.encode(object)
        case .null: try value.encodeNil()
        }
    }
    public var text: String? {
        switch self {
        case .string(let value): value
        case .number(let value): NSDecimalNumber(decimal: value).stringValue
        case .bool(let value): String(value)
        case .array(let values): values.compactMap(\.text).joined(separator: ", ")
        case .object, .null: nil
        }
    }
}

public enum VariationConvention: String, Codable, Sendable { case points, relativePercent, unavailable }

public struct WebstatSeriesDescriptor: Codable, Equatable, Sendable, Identifiable {
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
        decimals = text("decimals").flatMap(Int.init).map { min(max($0, 0), 10) }
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
            category: .markets, unit: unit, fractionDigits: decimals ?? 2, source: producer,
            sourceURL: sourceURL, isDemo: false, frequency: frequency, observations: observations,
            descriptor: self, syncedAt: syncedAt, hasCompleteHistory: completeHistory)
    }
    public static func isValidKey(_ key: String) -> Bool {
        key.count <= 300 && key.range(of: "^[A-Za-z0-9_][A-Za-z0-9_.-]*$", options: .regularExpression) != nil
    }
    static func date(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withFullDate]
        return formatter.date(from: String(value.prefix(10)))
    }
}

public struct WebstatDataset: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    public let raw: [String: WebstatValue]
    public var dimensionCodelists: [String: String] { WebstatSeriesDescriptor.dictionary(raw["dimensions_and_codelists"]?.text) }
    public var attributeCodelists: [String: String] { WebstatSeriesDescriptor.dictionary(raw["series_attributes_and_codelists"]?.text) }
    public var areaField: String? { ["REF_AREA", "AME_REF_AREA", "ZONE_GEO"].first { dimensionCodelists[$0] != nil }?.lowercased() }
    public var areaCodelist: String? { areaField.flatMap { dimensionCodelists[$0.uppercased()] } }
    public init(raw: [String: WebstatValue]) throws {
        guard let id = raw["dataset_id"]?.text else { throw WebstatClient.ClientError.invalidData }
        self.id = id
        title = raw["title_fr"]?.text ?? raw["name_fr"]?.text ?? id
        detail = raw["description_fr"]?.text ?? ""
        self.raw = raw
    }
}

public struct WebstatPage<Item: Sendable>: Sendable {
    public let items: [Item]
    public let total: Int
    public let offset: Int
    public var hasMore: Bool { offset + items.count < total }
}

public struct WebstatSearch: Equatable, Sendable {
    public var query: String
    public var datasetID: String
    public var area: String
    public var frequency: String
    public var areaField: String
    public init(query: String = "", datasetID: String = "", area: String = "", frequency: String = "", areaField: String = "ref_area") {
        self.query = query; self.datasetID = datasetID; self.area = area; self.frequency = frequency; self.areaField = areaField
    }
}
