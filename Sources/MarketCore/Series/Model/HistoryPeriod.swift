// Fenêtres de consultation de l’historique et horizons proposés à l’écran.
import Foundation

public enum HistoryPeriod: String, CaseIterable, Identifiable, Sendable {
    case month, quarter, halfYear, year, threeYears, fiveYears, all
    public var id: String { rawValue }
    /// Horizons proposés à l’écran, partagés par Focus et le bandeau ; les autres restent disponibles aux calculs.
    public static let visible: [HistoryPeriod] = [.quarter, .year, .threeYears, .fiveYears, .all]
    /// Years of recent history loaded by default, one more than the longest visible horizon.
    public static let recentYears = 6

    /// A tranche of history: `recentYears` calendar years ending at `end`, never starting before `first`.
    /// `isComplete` is true once the tranche reaches `first`, the start of the published history.
    public static func tranche(endingAt end: Date, notBefore first: Date? = nil, calendar: Calendar) -> (start: Date, end: Date, isComplete: Bool) {
        let windowStart = calendar.date(byAdding: .year, value: -recentYears, to: end)!
        guard let first else { return (windowStart, end, false) }
        let start = max(first, windowStart)
        return (start, end, start <= first)
    }

    /// Where the next older tranche ends: the day before the current one starts.
    public static func previousEnd(before start: Date) -> Date { start.addingTimeInterval(-.day) }
    public var days: Int {
        switch self { case .month: 30; case .quarter: 90; case .halfYear: 183; case .year: 365; case .threeYears: 1_095; case .fiveYears: 1_825; case .all: Int.max }
    }
    public var months: Int {
        switch self { case .month: 1; case .quarter: 3; case .halfYear: 6; case .year: 12; case .threeYears: 36; case .fiveYears: 60; case .all: 0 }
    }
    /// Compact label of the hub tabs; `title` stays the accessible name.
    public var shortTitle: String {
        switch self { case .month: "1M"; case .quarter: "3M"; case .halfYear: "6M"; case .year: "1A"; case .threeYears: "3A"; case .fiveYears: "5A"; case .all: "Max" }
    }
    public var title: String {
        switch self { case .month: "1 mois"; case .quarter: "3 mois"; case .halfYear: "6 mois"; case .year: "1 an"; case .threeYears: "3 ans"; case .fiveYears: "5 ans"; case .all: "Tout" }
    }
}
