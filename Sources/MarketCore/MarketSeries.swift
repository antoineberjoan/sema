import Foundation

public enum SeriesCategory: String, Codable, CaseIterable, Sendable {
    case markets, savings, funds
}

public enum ValueUnit: String, Codable, Sendable {
    case percent, usd, jpy, chf, eur

    public var symbol: String {
        switch self {
        case .percent: "%"
        case .usd: "USD"
        case .jpy: "JPY"
        case .chf: "CHF"
        case .eur: "€"
        }
    }
}

public enum HistoryPeriod: String, CaseIterable, Identifiable, Sendable {
    case month, quarter, year
    public var id: String { rawValue }
    public var days: Int {
        switch self { case .month: 30; case .quarter: 90; case .year: 365 }
    }
    public var title: String {
        switch self { case .month: "1 mois"; case .quarter: "3 mois"; case .year: "1 an" }
    }
}

public struct MarketObservation: Codable, Equatable, Sendable, Identifiable {
    public var id: Date { date }
    public let date: Date
    public let value: Decimal

    public init(date: Date, value: Decimal) {
        self.date = date
        self.value = value
    }
}

public struct MarketSeries: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let category: SeriesCategory
    public let unit: ValueUnit
    public let fractionDigits: Int
    public let source: String
    public let sourceURL: URL?
    public let isDemo: Bool
    public let observations: [MarketObservation]

    public init(
        id: String, name: String, subtitle: String, category: SeriesCategory,
        unit: ValueUnit, fractionDigits: Int = 2, source: String,
        sourceURL: URL? = nil, isDemo: Bool, observations: [MarketObservation]
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.category = category
        self.unit = unit
        self.fractionDigits = fractionDigits
        self.source = source
        self.sourceURL = sourceURL
        self.isDemo = isDemo
        // One publication per date; the last input for that date wins.
        let unique = Dictionary(observations.map { ($0.date, $0) }, uniquingKeysWith: { _, latest in latest })
        self.observations = unique.values.sorted { $0.date < $1.date }
    }

    public var latest: MarketObservation? { observations.last }

    public func history(for period: HistoryPeriod) -> [MarketObservation] {
        guard let latest else { return [] }
        let cutoff = latest.date.addingTimeInterval(-Double(period.days) * 86_400)
        return observations.filter { $0.date >= cutoff }
    }

    /// Rate changes use percentage points; exchange rates and NAVs use percent.
    public func change(for period: HistoryPeriod) -> Decimal? {
        let points = history(for: period)
        guard points.count > 1, let first = points.first, let last = points.last else { return nil }
        if unit == .percent { return last.value - first.value }
        guard first.value != 0 else { return nil }
        return (last.value - first.value) / first.value * 100
    }

    public var dailyChange: Decimal? {
        guard observations.count > 1 else { return nil }
        let previous = observations[observations.count - 2].value
        guard previous > 0, let latest else { return nil }
        return (latest.value - previous) / previous * 100
    }
}
