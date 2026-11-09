// Mouvement d’un autre repère suivi le même jour, calculé localement, avec son écart à l’habituel.
import Foundation

public struct PeerMove: Equatable, Identifiable, Sendable {
    public let series: MarketSeries
    public let change: Decimal
    public let ratio: Double?
    public var id: String { series.id }

    /// Followed series observed the same day as `day` (calendar day in UTC), ordered by their distance from the usual.
    public static func moves(on day: Date, among candidates: [MarketSeries], excluding seriesID: String) -> [PeerMove] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return candidates.compactMap { series -> PeerMove? in
            guard series.id != seriesID, series.variationConvention != .unavailable,
                  let index = series.observations.lastIndex(where: { calendar.isDate($0.date, inSameDayAs: day) }), index > 0 else { return nil }
            let move = UnusualMove(series: series, at: index)
            let previous = series.observations[index - 1].value
            let value = series.observations[index].value
            let change: Decimal
            if series.unit == .percent { change = value - previous }
            else if previous > 0 { change = (value - previous) / previous * 100 }
            else { return nil }
            return PeerMove(series: series, change: move?.change ?? change, ratio: move?.ratio)
        }.sorted { ($0.ratio ?? 0) > ($1.ratio ?? 0) }
    }
}
