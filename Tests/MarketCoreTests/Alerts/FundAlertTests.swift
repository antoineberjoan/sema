// Vérifie la règle de variation journalière, réservée aux repères de la catégorie des fonds.
import Foundation
import Testing
@testable import MarketCore

struct FundAlertTests {
    private let date = Date(timeIntervalSince1970: 1_792_022_400)

    private func series(_ values: [Decimal], category: SeriesCategory = .funds) -> MarketSeries {
        MarketSeries(id: "unit-a", name: "Test", subtitle: "Fixture", category: category,
                     unit: .eur, source: "Fixture",
                     observations: values.enumerated().map {
                         MarketObservation(date: date.addingTimeInterval(Double($0.offset) * 86_400), value: $0.element)
                     })
    }

    @Test func fallThresholdMustBeStrictlyExceeded() {
        let rule = AlertRule(seriesID: "unit-a", direction: .fall, threshold: 3)
        #expect(AlertEvaluator.evaluate(rule, series: series([100, 97])) == nil)
        let event = AlertEvaluator.evaluate(rule, series: series([100, Decimal(string: "96.99")!]))
        #expect(event != nil)
        #expect(event?.changePercent == Decimal(string: "-3.01")!)
    }

    @Test func riseRuleDoesNotTriggerOnAFall() {
        let rule = AlertRule(seriesID: "unit-a", direction: .rise, threshold: 2)
        #expect(AlertEvaluator.evaluate(rule, series: series([100, 95])) == nil)
        #expect(AlertEvaluator.evaluate(rule, series: series([100, 103])) != nil)
    }

    @Test func pausedRuleAndAnotherSeriesDoNotTrigger() {
        let paused = AlertRule(seriesID: "unit-a", direction: .fall, threshold: 3, isEnabled: false)
        let another = AlertRule(seriesID: "unit-b", direction: .fall, threshold: 3)
        #expect(AlertEvaluator.evaluate(paused, series: series([100, 90])) == nil)
        #expect(AlertEvaluator.evaluate(another, series: series([100, 90])) == nil)
    }

    @Test func alreadyNotifiedPublicationDoesNotTriggerAgain() {
        let item = series([100, 90])
        let rule = AlertRule(seriesID: item.id, direction: .fall, threshold: 3)
        #expect(AlertEvaluator.evaluate(rule, series: item, lastNotifiedAt: item.latest!.date) == nil)
        #expect(AlertEvaluator.evaluate(rule, series: item, lastNotifiedAt: date) != nil)
    }

    @Test func marketSeriesCannotTriggerFundAlerts() {
        let item = series([100, 90], category: .markets)
        let rule = AlertRule(seriesID: item.id, direction: .fall, threshold: 3)
        #expect(AlertEvaluator.evaluate(rule, series: item) == nil)
    }
}
