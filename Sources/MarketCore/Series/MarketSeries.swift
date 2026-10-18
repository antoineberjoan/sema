// Série économique avec sa provenance, ses observations et le calcul de ses variations.
import Foundation

public struct MarketSeries: Codable, Identifiable, Equatable, Sendable {
    /// Precision used when a provider does not publish one, and the widest precision accepted from a provider.
    public static let defaultFractionDigits = 2
    public static let maximumFractionDigits = 10
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
    public let statisticalDescriptor: StatisticalSeriesDescriptor?

    public init(
        id: String, name: String, subtitle: String, category: SeriesCategory,
        unit: ValueUnit, fractionDigits: Int = MarketSeries.defaultFractionDigits, source: String,
        sourceURL: URL? = nil, isDemo: Bool, frequency: ObservationFrequency? = nil,
        observations: [MarketObservation], descriptor: WebstatSeriesDescriptor? = nil,
        syncedAt: Date? = nil, hasCompleteHistory: Bool? = nil,
        statisticalDescriptor: StatisticalSeriesDescriptor? = nil
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
        self.statisticalDescriptor = statisticalDescriptor
        // One publication per date; the last input for that date wins.
        let unique = Dictionary(observations.map { ($0.date, $0) }, uniquingKeysWith: { _, latest in latest })
        self.observations = unique.values.sorted { $0.date < $1.date }
    }

    public var latest: MarketObservation? { observations.last }
    public var originBadge: String { statisticalDescriptor?.dataset.source.title ?? (sourceURL?.host == "webstat.banque-france.fr" ? "BdF" : "BCE") }
    public var variationConvention: VariationConvention {
        descriptor?.variation ?? statisticalDescriptor?.variation ?? (unit == .percent ? .points : .relativePercent)
    }
    public var displayUnit: String { descriptor?.displayUnit ?? statisticalDescriptor?.displayUnit ?? unit.symbol }
    public var canAlert: Bool { descriptor?.canAlert ?? statisticalDescriptor?.canAlert ?? (unit != .unknown) }

    public func replacing(observations: [MarketObservation], syncedAt: Date? = nil,
                          completeHistory: Bool? = nil, descriptor: WebstatSeriesDescriptor? = nil) -> MarketSeries {
        MarketSeries(id: id, name: name, subtitle: subtitle, category: category, unit: unit,
            fractionDigits: fractionDigits, source: source, sourceURL: sourceURL, isDemo: isDemo,
            frequency: frequency, observations: observations, descriptor: descriptor ?? self.descriptor,
            syncedAt: syncedAt ?? self.syncedAt, hasCompleteHistory: completeHistory ?? hasCompleteHistory,
            statisticalDescriptor: statisticalDescriptor)
    }

    public func withID(_ id: String) -> MarketSeries {
        MarketSeries(id: id, name: name, subtitle: subtitle, category: category, unit: unit,
            fractionDigits: fractionDigits, source: source, sourceURL: sourceURL, isDemo: isDemo,
            frequency: frequency, observations: observations, descriptor: descriptor,
            syncedAt: syncedAt, hasCompleteHistory: hasCompleteHistory, statisticalDescriptor: statisticalDescriptor)
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
        if [.monthly, .quarterly, .halfYearly, .yearly].contains(frequency) || period == .halfYear || period.days >= HistoryPeriod.year.days {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            return calendar.date(byAdding: .month, value: -period.months, to: date)!
        }
        return date.addingTimeInterval(-Double(period.days) * .day)
    }

    /// Rate changes use percentage points; exchange rates and NAVs use percent.
    public func change(for period: HistoryPeriod) -> Decimal? {
        let points = history(for: period)
        guard points.count > 1, let first = points.first, let last = points.last else { return nil }
        guard variationConvention != .unavailable else { return nil }
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
