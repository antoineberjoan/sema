// Vérifie le rang d’une séance (depuis quand, ou de tout l’historique), la phrase d’ouverture et le jour ouvré suivant.
import Foundation
import Testing
@testable import MarketCore

struct SessionRankTests {
    private let start = Date(timeIntervalSince1970: 1_700_006_400)

    /// Daily series with calm noise and sessions replaced by the given percent changes at the given indices.
    private func series(count: Int, drops: [Int: Decimal]) -> MarketSeries {
        var values: [Decimal] = [100]
        for index in 1..<count {
            let move = drops[index] ?? (index.isMultiple(of: 2) ? 0.2 : -0.2)
            values.append(values[index - 1] * (1 + move / 100))
        }
        return MarketSeries(id: "s", name: "S", subtitle: "Fixture", category: .markets, unit: .number, source: "Test",
                            observations: values.enumerated().map { MarketObservation(date: start.addingTimeInterval(Double($0.offset) * .day), value: $0.element) })
    }

    @Test func rankSaysSinceWhenAnEarlierSessionWasAsStrong() throws {
        let rank = try #require(SessionRank(series: series(count: 700, drops: [100: -6, 690: -4, 699: -4.4])))
        #expect(rank.direction == .fall)
        #expect((18...20).contains(try #require(rank.months)))
        #expect(rank.text.hasPrefix("Plus forte baisse depuis 1"))
    }

    @Test func rankSaysWholeHistoryWhenNoEarlierSessionMatches() throws {
        let rank = try #require(SessionRank(series: series(count: 800, drops: [799: -5])))
        #expect(rank.months == nil)
        #expect(rank.text.hasPrefix("Plus forte baisse de tout l’historique chargé"))
    }

    @Test func noRankWhenARecentSessionWasAsStrongOrHistoryIsShort() {
        #expect(SessionRank(series: series(count: 700, drops: [650: -6, 699: -4.4])) == nil)
        #expect(SessionRank(series: series(count: 100, drops: [99: -5])) == nil)
    }

    @Test func risesAreRankedAsRises() throws {
        let rank = try #require(SessionRank(series: series(count: 800, drops: [799: 5])))
        #expect(rank.direction == .rise)
        #expect(rank.text.contains("hausse"))
    }

    @Test func sentenceCountsMovesWithoutFiguresOrCauses() {
        func move(_ id: String, _ change: Decimal) -> PeerMove {
            PeerMove(series: MarketSeries(id: id, name: id, subtitle: "", category: .markets, unit: .number, source: "Test", observations: []), change: change, ratio: 3)
        }
        let all = [move("VIX", 70), move("Nasdaq 100", -5.5), move("Russell 2000", -4.5), move("S&P 500", -4.4)]
        #expect(SessionSentence.text(moves: all, name: \.name) == "4 de vos repères sont sortis de l’habituel : VIX en hausse ; Nasdaq 100, Russell 2000 et S&P 500 en baisse.")
        #expect(SessionSentence.text(moves: [all[1]], name: \.name) == "Un de vos repères est sorti de l’habituel : Nasdaq 100 en baisse.")
        #expect(SessionSentence.text(moves: [], name: \.name) == "Aucun de vos repères n’est sorti de l’habituel.")
    }

    @Test func nextDaySkipsTheWeekend() {
        let thursday = ISO8601DateFormatter().date(from: "2026-11-05T21:00:00Z")!
        let friday = ISO8601DateFormatter().date(from: "2026-11-06T12:00:00Z")!
        #expect(DayAgenda.nextDay(after: thursday) == friday)
        #expect(DayAgenda.nextDay(after: friday) == ISO8601DateFormatter().date(from: "2026-11-09T12:00:00Z")!)
    }
}
