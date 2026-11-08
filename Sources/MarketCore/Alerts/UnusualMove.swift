// Compare la variation d’une séance à la variation habituelle des 20 séances qui la précèdent.
import Foundation

public struct UnusualMove: Equatable, Sendable {
    /// Number of previous changes that define the usual variation.
    public static let window = 20

    /// Change of the session, in points for rates and in percent otherwise.
    public let change: Decimal
    /// Absolute change divided by the standard deviation of the previous changes.
    public let ratio: Double
    public let observation: MarketObservation

    /// Measures the move of the observation at `index`; nil without enough history,
    /// with an unknown variation convention, or when the previous changes never varied.
    public init?(series: MarketSeries, at index: Int) {
        let observations = series.observations
        guard observations.indices.contains(index), index > Self.window,
              series.variationConvention != .unavailable else { return nil }
        var changes: [Decimal] = []
        for position in (index - Self.window)...index {
            guard let change = Self.change(from: observations[position - 1].value, to: observations[position].value,
                                           points: series.unit == .percent) else { return nil }
            changes.append(change)
        }
        guard let latest = changes.popLast() else { return nil }
        let previous = changes.map { NSDecimalNumber(decimal: $0).doubleValue }
        let mean = previous.reduce(0, +) / Double(previous.count)
        let deviation = (previous.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(previous.count)).squareRoot()
        guard deviation > 0 else { return nil }
        change = latest
        ratio = abs(NSDecimalNumber(decimal: latest).doubleValue) / deviation
        observation = observations[index]
    }

    /// Move of the latest observation.
    public init?(series: MarketSeries) {
        self.init(series: series, at: series.observations.count - 1)
    }

    private static func change(from previous: Decimal, to value: Decimal, points: Bool) -> Decimal? {
        if points { return value - previous }
        guard previous > 0 else { return nil }
        return (value - previous) / previous * 100
    }
}
