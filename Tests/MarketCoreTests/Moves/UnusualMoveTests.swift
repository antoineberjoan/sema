// Vérifie le calcul du mouvement inhabituel, ses conventions, ses refus et son anti-doublon.
import Foundation
import Testing
@testable import MarketCore

struct UnusualMoveTests {
    private let start = Date(timeIntervalSince1970: 1_792_022_400)

    /// Vingt et une clôtures qui alternent ±1 % autour de 100, puis une dernière séance avec la variation donnée en pourcent.
    private func market(lastChange: Decimal, id: String = "spy") -> MarketSeries {
        var values: [Decimal] = [100]
        for index in 0..<UnusualMove.window { values.append(values[values.count - 1] * (index.isMultiple(of: 2) ? 1.01 : 0.99)) }
        values.append(values[values.count - 1] * (1 + lastChange / 100))
        return MarketSeries(id: id, name: "SPY", subtitle: "Fixture", category: .markets, unit: .number, source: "Test",
                            observations: values.enumerated().map {
            MarketObservation(date: start.addingTimeInterval(Double($0.offset) * .day), value: $0.element)
        })
    }

    @Test func ratioComparesTheSessionWithTheUsualVariation() throws {
        let move = try #require(UnusualMove(series: market(lastChange: -4)))
        #expect(move.change < -3.99 && move.change > -4.01)
        #expect(move.ratio > 3.9 && move.ratio < 4.1)
        #expect(UnusualMove(series: market(lastChange: 0.5))!.ratio < 1)
    }

    @Test func ratesUsePointsAndShortOrFlatHistoriesAreRefused() {
        let rates = MarketSeries(id: "us10", name: "Taux", subtitle: "Fixture", category: .markets, unit: .percent, source: "Test",
                                 observations: (0...UnusualMove.window + 1).map {
            MarketObservation(date: start.addingTimeInterval(Double($0) * .day),
                              value: $0 == UnusualMove.window + 1 ? Decimal(4.6) : ($0.isMultiple(of: 2) ? Decimal(4.1) : Decimal(4)))
        })
        #expect(UnusualMove(series: rates).map { $0.change > 0.49 && $0.change < 0.61 } == true)
        let short = MarketSeries(id: "spy", name: "SPY", subtitle: "Fixture", category: .markets, unit: .number, source: "Test",
                                 observations: Array(market(lastChange: -4).observations.suffix(UnusualMove.window)))
        #expect(UnusualMove(series: short) == nil)
        let flat = MarketSeries(id: "spy", name: "SPY", subtitle: "Fixture", category: .markets, unit: .number, source: "Test",
                                observations: (0...UnusualMove.window + 1).map {
            MarketObservation(date: start.addingTimeInterval(Double($0) * .day), value: 100)
        })
        #expect(UnusualMove(series: flat) == nil)
    }

    @Test func eventsFollowSensitivityAndFireOncePerSession() throws {
        let series = market(lastChange: -4)
        let checkpoint = series.observations[series.observations.count - 2].date
        var rule = AlertRule.unusualMove(seriesID: "spy", lastEvaluatedAt: checkpoint)
        #expect(rule.isValid)
        let events = AlertEvaluator.newEvents(rule, series: series)
        #expect(events.count == 1)
        #expect(events.first?.ratio.map { $0 > 3.9 } == true)
        #expect(AlertEvaluator.newEvents(rule, series: market(lastChange: -2.5), sensitivity: .discreet).isEmpty)
        #expect(AlertEvaluator.newEvents(rule, series: market(lastChange: -2.5), sensitivity: .normal).count == 1)
        rule.lastEvaluatedAt = series.latest?.date
        let restored = try JSONDecoder().decode(AlertRule.self, from: JSONEncoder().encode(rule))
        #expect(AlertEvaluator.newEvents(restored, series: series).isEmpty)
    }

    @Test func sensitivityIsOptionalInPreferences() throws {
        let storedV1 = Data("""
        {"schemaVersion":2,"favoriteIDs":[],"followedSeriesIDs":[],"alerts":[],"notificationsEnabled":false}
        """.utf8)
        var value = try JSONDecoder().decode(AppPreferences.self, from: storedV1)
        #expect(value.moveSensitivityID == nil)
        value.moveSensitivityID = MoveSensitivity.attentive.rawValue
        let restored = try JSONDecoder().decode(AppPreferences.self, from: JSONEncoder().encode(value))
        #expect(MoveSensitivity(rawValue: restored.moveSensitivityID ?? "") == .attentive)
        #expect(MoveSensitivity.allCases.map(\.multiplier) == [3, 2, 1.5])
    }
}
