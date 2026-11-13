// Vérifie la reprise des points de contrôle, les règles à réinitialiser et les sources suspendues.
import Foundation
import Testing
@testable import MarketCore

struct AlertCheckTests {
    private let start = Date(timeIntervalSince1970: 1_792_022_400)

    private func rate(_ values: [Decimal], id: String = "ecb") -> MarketSeries {
        MarketSeries(id: id, name: "Taux", subtitle: "Fixture", category: .savings, unit: .percent,
                     source: "Test", observations: values.enumerated().map {
            MarketObservation(date: start.addingTimeInterval(Double($0.offset) * 86_400), value: $0.element)
        })
    }

    private func check(_ rule: AlertRule, baseline: Set<UUID>? = nil, values: [MarketSeries],
                       enabled: Bool = true) -> AlertCheck {
        AlertEvaluator.check(rules: [rule], baselineIDs: baseline, series: values, sensitivity: .standard) { _ in enabled }
    }

    @Test func newPublicationEmitsEventsAndMovesTheCheckpoint() {
        let rule = AlertRule(seriesID: "ecb", direction: .rise, threshold: 3, condition: .level, lastEvaluatedAt: start)
        let result = check(rule, values: [rate([2, 4])])
        #expect(result.events.count == 1)
        #expect(result.hasAdvanced)
        #expect(result.rules[0].lastEvaluatedAt == start.addingTimeInterval(86_400))
    }

    @Test func publicationAlreadyCheckedChangesNothing() {
        let rule = AlertRule(seriesID: "ecb", direction: .rise, threshold: 3, condition: .level,
                             lastEvaluatedAt: start.addingTimeInterval(86_400))
        let result = check(rule, values: [rate([2, 4])])
        #expect(result.events.isEmpty)
        #expect(!result.hasAdvanced)
        #expect(result.rules == [rule])
    }

    @Test func ruleToResetResumesAtTheLatestObservationWithoutEvent() {
        let rule = AlertRule(seriesID: "ecb", direction: .rise, threshold: 3, condition: .level, lastEvaluatedAt: start)
        let result = check(rule, baseline: [rule.id], values: [rate([2, 4])])
        #expect(result.events.isEmpty)
        #expect(result.hasAdvanced)
        #expect(result.baselineIDs == [])
        #expect(result.rules[0].lastEvaluatedAt == start.addingTimeInterval(86_400))
    }

    @Test func suspendedSourceIsLeftUntouched() {
        let rule = AlertRule(seriesID: "ecb", direction: .rise, threshold: 3, condition: .level, lastEvaluatedAt: start)
        let result = check(rule, values: [rate([2, 4])], enabled: false)
        #expect(result.events.isEmpty)
        #expect(!result.hasAdvanced)
        #expect(result.rules == [rule])
    }

    @Test func testSampleStraddlesTheThresholdInTheRuleDirection() throws {
        let rise = AlertRule(seriesID: "ecb", direction: .rise, threshold: 3, condition: .level)
        let sample = AlertEvaluator.testSample(for: rise, series: rate([2, 2]), now: start)
        #expect(sample.observations.map(\.value) == [Decimal(string: "2.9")!, Decimal(string: "3.1")!])
        #expect(AlertEvaluator.evaluate(rise, series: sample) != nil)
        let fall = AlertRule(seriesID: "ecb", direction: .fall, threshold: 3, condition: .level)
        let down = AlertEvaluator.testSample(for: fall, series: rate([4, 4]), now: start)
        #expect(AlertEvaluator.evaluate(fall, series: down) != nil)
    }
}
