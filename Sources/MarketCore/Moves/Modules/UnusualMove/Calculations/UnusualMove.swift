// Compare la variation d’une séance à la variation habituelle des 20 séances qui la précèdent.
import Foundation

public struct UnusualMove: Equatable, Sendable {
    /// Nombre de variations précédentes qui définissent la variation habituelle.
    public static let window = 20

    /// Variation de la séance, en points pour les taux et en pourcent sinon.
    public let change: Decimal
    /// Variation absolue divisée par l’écart-type des variations précédentes.
    public let ratio: Double
    public let observation: MarketObservation

    /// Mesure le mouvement de l’observation à `index` ; nil sans assez d’historique,
    /// avec une convention de variation inconnue, ou quand les variations précédentes n’ont jamais varié.
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

    /// Mouvement de la dernière observation.
    public init?(series: MarketSeries) {
        self.init(series: series, at: series.observations.count - 1)
    }

    static func change(from previous: Decimal, to value: Decimal, points: Bool) -> Decimal? {
        if points { return value - previous }
        guard previous > 0 else { return nil }
        return (value - previous) / previous * 100
    }
}
