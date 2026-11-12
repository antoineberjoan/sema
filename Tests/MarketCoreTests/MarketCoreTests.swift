// Vérifie les modèles, variations et contrats de persistance du cœur.
import Foundation
import Testing
@testable import MarketCore

struct MarketCoreTests {
    private let date = Date(timeIntervalSince1970: 1_792_022_400)

    private func series(_ values: [Decimal], id: String = "fund-i-eur", unit: ValueUnit = .eur,
                        category: SeriesCategory = .funds) -> MarketSeries {
        MarketSeries(id: id, name: "Test", subtitle: "Part I · EUR", category: category,
                     unit: unit, source: "Fixture",
                     observations: values.enumerated().map {
                         MarketObservation(date: date.addingTimeInterval(Double($0.offset) * 86_400), value: $0.element)
                     })
    }

    @Test
    func testRateChangeIsInPercentagePoints() {
        let rate = series([2, Decimal(string: "2.5")!], unit: .percent, category: .markets)
        #expect(rate.change(for: .month) == Decimal(string: "0.5")!)
    }

    @Test
    func testNAVChangeIsRelativePercent() {
        #expect(series([100, 105]).change(for: .month) == 5)
        #expect(series([100, 95]).dailyChange == -5)
    }

    @Test
    func testZeroBaselineDoesNotProduceAnInfiniteReturn() {
        #expect(series([0, 10]).dailyChange == nil)
        #expect(series([0, 10]).change(for: .month) == nil)
    }

    @Test
    func testHistoryWindowUsesObservationDatesRatherThanCurrentTime() {
        let value = series((0...40).map { Decimal($0 + 100) })
        #expect(value.history(for: .month).count == 31)
        #expect(value.history(for: .month).first?.value == 110)
    }

    @Test
    func testObservationsAreSortedAndDuplicatePublicationIsReplaced() {
        let item = MarketSeries(id: "x", name: "x", subtitle: "", category: .markets,
            unit: .usd, source: "Test",
            observations: [MarketObservation(date: date, value: 2),
                           MarketObservation(date: date.addingTimeInterval(-86_400), value: 1),
                           MarketObservation(date: date, value: 3)])
        #expect(item.observations.map(\.value) == [1, 3])
    }

    @Test
    func testFallThresholdMustBeStrictlyExceeded() {
        let rule = AlertRule(seriesID: "fund-i-eur", direction: .fall, threshold: 3)
        #expect(AlertEvaluator.evaluate(rule, series: series([100, 97])) == nil)
        let event = AlertEvaluator.evaluate(rule, series: series([100, Decimal(string: "96.99")!]))
        #expect(event != nil)
        #expect(event?.changePercent == Decimal(string: "-3.01")!)
    }

    @Test
    func testRiseRuleDoesNotTriggerOnAFall() {
        let rule = AlertRule(seriesID: "fund-i-eur", direction: .rise, threshold: 2)
        #expect(AlertEvaluator.evaluate(rule, series: series([100, 95])) == nil)
        #expect(AlertEvaluator.evaluate(rule, series: series([100, 103])) != nil)
    }

    @Test
    func testPausedRuleAndAnotherShareClassDoNotTrigger() {
        let paused = AlertRule(seriesID: "fund-i-eur", direction: .fall, threshold: 3, isEnabled: false)
        let anotherPart = AlertRule(seriesID: "fund-r-eur", direction: .fall, threshold: 3)
        #expect(AlertEvaluator.evaluate(paused, series: series([100, 90])) == nil)
        #expect(AlertEvaluator.evaluate(anotherPart, series: series([100, 90])) == nil)
    }

    @Test
    func testAlreadyNotifiedPublicationDoesNotTriggerAgain() {
        let item = series([100, 90])
        let rule = AlertRule(seriesID: item.id, direction: .fall, threshold: 3)
        #expect(AlertEvaluator.evaluate(rule, series: item, lastNotifiedAt: item.latest!.date) == nil)
        #expect(AlertEvaluator.evaluate(rule, series: item, lastNotifiedAt: date) != nil)
    }

    @Test
    func testMacroSeriesCannotTriggerFundAlerts() {
        let item = series([100, 90], category: .markets)
        let rule = AlertRule(seriesID: item.id, direction: .fall, threshold: 3)
        #expect(AlertEvaluator.evaluate(rule, series: item) == nil)
    }

    @Test
    func testThresholdAcceptsFrenchDecimalsAndRejectsPartialOrInvalidValues() {
        #expect(AlertThreshold.parse("2,5") == Decimal(string: "2.5")!)
        #expect(AlertThreshold.parse(" 2.50 ") == Decimal(string: "2.5")!)
        for input in ["", "0", "-2", "101", "2foo", "NaN", "2,5,6", "1e2"] {
            #expect(AlertThreshold.parse(input) == nil)
        }
    }

    @Test
    func testPreferencesPersistFavoritesAndDecimalAlertThreshold() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-test-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PreferencesRepository(fileURL: directory.appendingPathComponent("preferences.json"))
        var preferences = AppPreferences(favoriteIDs: ["atlas-i-eur", "eurusd"])
        preferences.alerts = [AlertRule(seriesID: "atlas-i-eur", direction: .fall, threshold: Decimal(string: "2.5")!)]
        try store.save(preferences)
        #expect(try store.load() == preferences)
    }

    @Test
    func testUnreadableOrFuturePreferencesAreNotSilentlyAccepted() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-test-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("preferences.json")
        let store = PreferencesRepository(fileURL: file)
        try Data("broken".utf8).write(to: file)
        #expect(throws: (any Error).self) { _ = try store.load() }
        #expect(try String(contentsOf: file, encoding: .utf8) == "broken")
        var future = AppPreferences()
        future.schemaVersion = 99
        try JSONEncoder().encode(future).write(to: file)
        #expect(throws: (any Error).self) { _ = try store.load() }
    }


}
