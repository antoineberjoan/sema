// Agenda d’un jour : les faits du jour classés par importance, trois affichés d’abord, et la semaine ouvrée qui les porte.
import Foundation

public struct DayAgenda: Equatable, Sendable {
    /// Lines shown before « Tout voir ».
    public static let shownLimit = 3
    /// Monday to Friday.
    static let weekLength = 5
    /// Noon UTC keeps the calendar day stable in every time zone.
    static let noon = 12

    public let day: Date
    /// Every line of the day, in this order: unusual moves (largest gap first), releases of the FRED series
    /// the person follows, other FRED releases, central bank releases, headlines (newest first).
    public let items: [AgendaItem]
    public var shown: [AgendaItem] { Array(items.prefix(Self.shownLimit)) }
    public var hiddenCount: Int { max(0, items.count - Self.shownLimit) }

    public init(day: Date, series: [MarketSeries], sensitivity: MoveSensitivity,
                releases: [EconomicRelease], pressReleases: [PressRelease], headlines: [Headline]) {
        self.day = day
        let moves = Self.moves(on: day, series: series, sensitivity: sensitivity)
        let followed = Set(series.compactMap(\.statisticalDescriptor).filter { $0.dataset.source == .fred }.map(\.dataset.code))
        items = moves.map(AgendaItem.move)
            + releases.filter { followed.contains($0.releaseID) }.map(AgendaItem.release)
            + releases.filter { !followed.contains($0.releaseID) }.map(AgendaItem.release)
            + pressReleases.sorted { $0.publishedAt > $1.publishedAt }.map(AgendaItem.pressRelease)
            + headlines.sorted { $0.publishedAt > $1.publishedAt }.map(AgendaItem.headline)
    }

    /// Moves of the day that reach the chosen sensitivity, largest gap first.
    static func moves(on day: Date, series: [MarketSeries], sensitivity: MoveSensitivity) -> [PeerMove] {
        PeerMove.moves(on: day, among: series, excluding: "").filter { ($0.ratio ?? 0) >= sensitivity.multiplier }
    }

    public static func hasUnusualMove(on day: Date, series: [MarketSeries], sensitivity: MoveSensitivity) -> Bool {
        !moves(on: day, series: series, sensitivity: sensitivity).isEmpty
    }

    /// The five working days of the week of `date`, each at noon UTC.
    public static func week(containing date: Date, calendar: Calendar = Calendar(identifier: .iso8601)) -> [Date] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        return (0..<weekLength).compactMap { offset in
            guard let local = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let parts = calendar.dateComponents([.year, .month, .day], from: local)
            return utc.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day, hour: noon))
        }
    }

    /// The working day after `day`, at noon UTC: Friday leads to Monday.
    public static func nextDay(after day: Date) -> Date {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        var next = utc.date(byAdding: .day, value: 1, to: day) ?? day
        // Weekday 1 is Sunday and 7 is Saturday on the Gregorian calendar.
        while [1, 7].contains(utc.component(.weekday, from: next)) { next = utc.date(byAdding: .day, value: 1, to: next) ?? next }
        let parts = utc.dateComponents([.year, .month, .day], from: next)
        return utc.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day, hour: noon)) ?? next
    }

    /// The day opened first: today, or the last working day on a weekend.
    public static func currentDay(now: Date, calendar: Calendar = Calendar(identifier: .iso8601)) -> Date? {
        let days = week(containing: now, calendar: calendar)
        let today = calendar.dateComponents([.year, .month, .day], from: now)
        return days.first { day in
            var utc = Calendar(identifier: .gregorian)
            utc.timeZone = TimeZone(secondsFromGMT: 0)!
            let parts = utc.dateComponents([.year, .month, .day], from: day)
            return parts.year == today.year && parts.month == today.month && parts.day == today.day
        } ?? days.last
    }
}
