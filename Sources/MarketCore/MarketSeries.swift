import Foundation

public enum SeriesCategory: String, Codable, CaseIterable, Sendable {
    case markets, savings, funds
}

public enum ValueUnit: String, Codable, Sendable {
    case percent, usd, jpy, chf, gbp, eur, index, number, unknown

    public var symbol: String {
        switch self {
        case .percent: "%"
        case .usd: "USD"
        case .jpy: "JPY"
        case .chf: "CHF"
        case .gbp: "GBP"
        case .eur: "€"
        case .index: "indice"
        case .number: ""
        case .unknown: "Unité non interprétée"
        }
    }
}

public enum ObservationFrequency: String, Codable, Sendable {
    case daily, businessDaily, weekly, monthly, quarterly, halfYearly, yearly, unknown

    public var title: String {
        switch self {
        case .daily: "Quotidien"
        case .businessDaily: "Jours ouvrés"
        case .weekly: "Hebdomadaire"
        case .monthly: "Mensuel"
        case .quarterly: "Trimestriel"
        case .halfYearly: "Semestriel"
        case .yearly: "Annuel"
        case .unknown: "Fréquence non interprétée"
        }
    }
}

public enum HistoryPeriod: String, CaseIterable, Identifiable, Sendable {
    case month, quarter, halfYear, year, threeYears, fiveYears, all
    public var id: String { rawValue }
    public var days: Int {
        switch self { case .month: 30; case .quarter: 90; case .halfYear: 183; case .year: 365; case .threeYears: 1_095; case .fiveYears: 1_825; case .all: Int.max }
    }
    public var months: Int {
        switch self { case .month: 1; case .quarter: 3; case .halfYear: 6; case .year: 12; case .threeYears: 36; case .fiveYears: 60; case .all: 0 }
    }
    public var title: String {
        switch self { case .month: "1 mois"; case .quarter: "3 mois"; case .halfYear: "6 mois"; case .year: "1 an"; case .threeYears: "3 ans"; case .fiveYears: "5 ans"; case .all: "Tout" }
    }
}

public struct MarketObservation: Codable, Equatable, Sendable, Identifiable {
    public var id: Date { date }
    public let date: Date
    public let value: Decimal
    public let periodEnd: Date?
    public let updatedAt: Date?
    public let status: String?

    public init(date: Date, value: Decimal, periodEnd: Date? = nil,
                updatedAt: Date? = nil, status: String? = nil) {
        self.date = date
        self.value = value
        self.periodEnd = periodEnd
        self.updatedAt = updatedAt
        self.status = status
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
    public let frequency: ObservationFrequency?
    public let observations: [MarketObservation]
    public let descriptor: WebstatSeriesDescriptor?
    public let syncedAt: Date?
    public let hasCompleteHistory: Bool?

    public init(
        id: String, name: String, subtitle: String, category: SeriesCategory,
        unit: ValueUnit, fractionDigits: Int = 2, source: String,
        sourceURL: URL? = nil, isDemo: Bool, frequency: ObservationFrequency? = nil,
        observations: [MarketObservation], descriptor: WebstatSeriesDescriptor? = nil,
        syncedAt: Date? = nil, hasCompleteHistory: Bool? = nil
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
        self.frequency = frequency
        self.descriptor = descriptor
        self.syncedAt = syncedAt
        self.hasCompleteHistory = hasCompleteHistory
        // One publication per date; the last input for that date wins.
        let unique = Dictionary(observations.map { ($0.date, $0) }, uniquingKeysWith: { _, latest in latest })
        self.observations = unique.values.sorted { $0.date < $1.date }
    }

    public var latest: MarketObservation? { observations.last }
    public var displayUnit: String { descriptor?.displayUnit ?? unit.symbol }
    public var canAlert: Bool { descriptor?.canAlert ?? (unit != .unknown) }

    public func replacing(observations: [MarketObservation], syncedAt: Date? = nil,
                          completeHistory: Bool? = nil, descriptor: WebstatSeriesDescriptor? = nil) -> MarketSeries {
        MarketSeries(id: id, name: name, subtitle: subtitle, category: category, unit: unit,
            fractionDigits: fractionDigits, source: source, sourceURL: sourceURL, isDemo: isDemo,
            frequency: frequency, observations: observations, descriptor: descriptor ?? self.descriptor,
            syncedAt: syncedAt ?? self.syncedAt, hasCompleteHistory: completeHistory ?? hasCompleteHistory)
    }

    public func withID(_ id: String) -> MarketSeries {
        MarketSeries(id: id, name: name, subtitle: subtitle, category: category, unit: unit,
            fractionDigits: fractionDigits, source: source, sourceURL: sourceURL, isDemo: isDemo,
            frequency: frequency, observations: observations, descriptor: descriptor,
            syncedAt: syncedAt, hasCompleteHistory: hasCompleteHistory)
    }

    public func history(for period: HistoryPeriod) -> [MarketObservation] {
        if period == .all { return observations }
        guard let latest else { return [] }
        let cutoff = cutoff(for: period, endingAt: latest.date)
        return observations.filter { $0.date >= cutoff }
    }

    public func supports(_ period: HistoryPeriod) -> Bool {
        if period == .all { return !observations.isEmpty }
        guard let first = observations.first, let latest else { return false }
        return history(for: period).count > 1 && first.date <= cutoff(for: period, endingAt: latest.date)
    }

    public var hasAnnualHistory: Bool { supports(.year) }

    private func cutoff(for period: HistoryPeriod, endingAt date: Date) -> Date {
        if [.monthly, .quarterly, .halfYearly, .yearly].contains(frequency) || period == .halfYear || period.days >= 365 {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            return calendar.date(byAdding: .month, value: -period.months, to: date)!
        }
        return date.addingTimeInterval(-Double(period.days) * 86_400)
    }

    /// Rate changes use percentage points; exchange rates and NAVs use percent.
    public func change(for period: HistoryPeriod) -> Decimal? {
        let points = history(for: period)
        guard points.count > 1, let first = points.first, let last = points.last else { return nil }
        guard descriptor?.variation != .unavailable else { return nil }
        if unit == .percent { return last.value - first.value }
        guard first.value > 0, last.value >= 0 else { return nil }
        return (last.value - first.value) / first.value * 100
    }

    public var dailyChange: Decimal? {
        guard observations.count > 1 else { return nil }
        let previous = observations[observations.count - 2].value
        guard previous > 0, let latest else { return nil }
        return (latest.value - previous) / previous * 100
    }
}
