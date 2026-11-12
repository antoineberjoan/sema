// Vérifie les seuils stricts, la déduplication et la reprise des évaluations d’alertes.
import Foundation
import Testing
@testable import MarketCore

struct MacroAlertTests {
    private let start = Date(timeIntervalSince1970: 1_792_022_400)

    private func rate(_ values: [Decimal], id: String = "ecb", category: SeriesCategory = .savings) -> MarketSeries {
        MarketSeries(id: id, name: "Taux", subtitle: "Fixture", category: category, unit: .percent,
                     source: "Test", observations: values.enumerated().map {
            MarketObservation(date: start.addingTimeInterval(Double($0.offset) * 86_400), value: $0.element)
        })
    }

    @Test func levelCrossingsAreStrictAndDoNotRepeatWhileAbove() {
        let above = AlertRule(seriesID: "ecb", direction: .rise, threshold: 3, condition: .level)
        #expect(AlertEvaluator.evaluate(above, series: rate([2, 3])) == nil)
        #expect(AlertEvaluator.evaluate(above, series: rate([3, 4]))?.observedValue == 4)
        #expect(AlertEvaluator.evaluate(above, series: rate([4, 5])) == nil)
        #expect(AlertEvaluator.evaluate(above, series: rate([4, 2])) == nil)
        let below = AlertRule(seriesID: "ecb", direction: .fall, threshold: 3, condition: .level)
        #expect(AlertEvaluator.evaluate(below, series: rate([4, 3])) == nil)
        #expect(AlertEvaluator.evaluate(below, series: rate([3, 2]))?.observedValue == 2)
        #expect(AlertEvaluator.evaluate(below, series: rate([2, 1])) == nil)
    }

    @Test func zeroAndNegativeRatesAreComparedAsLevels() {
        let below = AlertRule(seriesID: "ecb", direction: .fall, threshold: 0, condition: .level)
        #expect(below.isValid)
        #expect(AlertEvaluator.evaluate(below, series: rate([0, -1]))?.observedValue == -1)
        let above = AlertRule(seriesID: "ecb", direction: .rise, threshold: -1, condition: .level)
        #expect(AlertEvaluator.evaluate(above, series: rate([-2, 0]))?.observedValue == 0)
    }

    @Test func catchesIntermediateCrossingsAndPersistsTheCheckpoint() throws {
        let item = rate([2, 4, 2, 5, 6])
        var rule = AlertRule(seriesID: "ecb", direction: .rise, threshold: 3,
                             condition: .level, lastEvaluatedAt: start)
        let events = AlertEvaluator.newEvents(rule, series: item)
        #expect(events.map(\.observedValue) == [4, 5])
        rule.lastEvaluatedAt = item.latest?.date
        let restored = try JSONDecoder().decode(AlertRule.self, from: JSONEncoder().encode(rule))
        #expect(AlertEvaluator.newEvents(restored, series: item).isEmpty)
        #expect(AlertEvaluator.newEvents(restored, series: rate([2, 4, 2, 5, 6, 2, 4])).count == 1)
    }

    @Test func initialConnectionUnsupportedCategoryPauseAndWrongSeriesCannotEmitSignals() {
        let item = rate([2, 4])
        var rule = AlertRule(seriesID: "ecb", direction: .rise, threshold: 3, condition: .level)
        #expect(AlertEvaluator.newEvents(rule, series: item).isEmpty)
        rule.lastEvaluatedAt = start
        #expect(AlertEvaluator.newEvents(rule, series: rate([2, 4], category: .funds)).isEmpty)
        #expect(AlertEvaluator.newEvents(rule, series: rate([2, 4], id: "fr10")).isEmpty)
        rule.isEnabled = false
        #expect(AlertEvaluator.newEvents(rule, series: item).isEmpty)
    }

    @Test func thresholdParsingSupportsRatesAndYenWithoutPartialParsing() {
        #expect(AlertThreshold.parseLevel(" -0,25 ") == Decimal(string: "-0.25"))
        #expect(AlertThreshold.parseLevel("0") == 0)
        #expect(AlertThreshold.parseLevel("175.1234") == Decimal(string: "175.1234"))
        #expect(AlertThreshold.parseLevel("0,123456789012345") == Decimal(string: "0.123456789012345"))
        for input in ["", "3%", "3foo", "NaN", "1e2", "2,5,6", "0,1234567890123456789"] {
            #expect(AlertThreshold.parseLevel(input) == nil)
        }
    }

    @Test func legacyPreferencesAndFundRulesRemainReadableWithoutReinterpretation() throws {
        let old = Data("""
        {"schemaVersion":1,"favoriteIDs":["atlas-i-eur","fr10"],"notificationsEnabled":false,
         "alerts":[{"id":"0F1396B5-51D9-42B3-A6DC-75E16B00D144","seriesID":"atlas-i-eur",
                    "direction":"fall","threshold":3,"isEnabled":true}]}
        """.utf8)
        var preferences = try JSONDecoder().decode(AppPreferences.self, from: old)
        #expect(preferences.themeID == nil)
        #expect(preferences.ribbonPositionID == nil)
        #expect(preferences.alerts.first?.effectiveCondition == .relativeChange)
        #expect(preferences.favoriteIDs.contains("atlas-i-eur"))
        preferences.themeID = "lavender"
        preferences.ribbonPositionID = "right"
        preferences.alerts.append(AlertRule(seriesID: "inflation", direction: .fall, threshold: 0,
                                            condition: .level, lastEvaluatedAt: start))
        let restored = try JSONDecoder().decode(AppPreferences.self, from: JSONEncoder().encode(preferences))
        #expect(restored == preferences)
        #expect(restored.alerts.count == 2)
    }
}
