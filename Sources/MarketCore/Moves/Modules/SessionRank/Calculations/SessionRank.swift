// Rang d’une séance dans l’historique chargé d’un repère : depuis quand une séance aussi forte, dans le même sens, ne s’était pas produite.
import Foundation

public struct SessionRank: Equatable, Sendable {
    public enum Direction: Sendable { case rise, fall }

    /// En dessous, la séance ne mérite pas de remarque.
    public static let minimumMonths = 3
    /// Sans séance égale plus ancienne, l’historique doit avoir au moins cette longueur pour affirmer « de tout l’historique ».
    public static let minimumHistoryMonths = 12
    private static let monthsPerYear = 12
    private static let yearsOnlyFrom = 24

    public let direction: Direction
    /// Mois depuis une séance égale ou plus forte dans le même sens ; nil quand l’historique chargé n’en contient aucune.
    public let months: Int?
    public let historyMonths: Int

    public init?(series: MarketSeries) { self.init(series: series, at: series.observations.count - 1) }

    public init?(series: MarketSeries, at index: Int) {
        let observations = series.observations
        guard observations.indices.contains(index), index > 0, series.variationConvention != .unavailable else { return nil }
        let points = series.unit == .percent
        func change(_ position: Int) -> Decimal? {
            UnusualMove.change(from: observations[position - 1].value, to: observations[position].value, points: points)
        }
        guard let latest = change(index), latest != 0 else { return nil }
        let rising = latest > 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        func monthsSince(_ start: Date) -> Int { calendar.dateComponents([.month], from: start, to: observations[index].date).month ?? 0 }
        var earlier: Int?
        for position in stride(from: index - 1, through: 1, by: -1) {
            guard let value = change(position), (value > 0) == rising, abs(value) >= abs(latest) else { continue }
            earlier = monthsSince(observations[position].date); break
        }
        direction = rising ? .rise : .fall
        historyMonths = monthsSince(observations[0].date)
        if let earlier {
            guard earlier >= Self.minimumMonths else { return nil }
            months = earlier
        } else {
            guard historyMonths >= Self.minimumHistoryMonths else { return nil }
            months = nil
        }
    }

    /// Lecture du rang, par exemple « Plus forte baisse depuis 18 mois ».
    public var text: String {
        let word = direction == .rise ? "hausse" : "baisse"
        guard let months else { return "Plus forte \(word) de tout l’historique chargé (\(Self.duration(historyMonths)))" }
        return "Plus forte \(word) depuis \(Self.duration(months))"
    }

    private static func duration(_ months: Int) -> String {
        months < yearsOnlyFrom ? "\(months) mois" : "\(months / monthsPerYear) ans"
    }
}
