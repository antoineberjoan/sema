// Vérifie les variations, la fenêtre d'historique et la fusion des observations d'une série.
import Foundation
import Testing
@testable import MarketCore

struct MarketSeriesTests {
    private let date = Date(timeIntervalSince1970: 1_792_022_400)

    private func series(_ values: [Decimal], unit: ValueUnit = .eur) -> MarketSeries {
        MarketSeries(id: "index-eur", name: "Indice", subtitle: "Fixture", category: .markets,
                     unit: unit, source: "Fixture",
                     observations: values.enumerated().map {
                         MarketObservation(date: date.addingTimeInterval(Double($0.offset) * 86_400), value: $0.element)
                     })
    }

    @Test func rateChangeIsInPercentagePoints() {
        let rate = series([2, Decimal(string: "2.5")!], unit: .percent)
        #expect(rate.change(for: .month) == Decimal(string: "0.5")!)
    }

    @Test func priceChangeIsRelativePercent() {
        #expect(series([100, 105]).change(for: .month) == 5)
        #expect(series([100, 95]).dailyChange == -5)
    }

    @Test func zeroBaselineDoesNotProduceAnInfiniteReturn() {
        #expect(series([0, 10]).dailyChange == nil)
        #expect(series([0, 10]).change(for: .month) == nil)
    }

    @Test func historyWindowUsesObservationDatesRatherThanCurrentTime() {
        let value = series((0...40).map { Decimal($0 + 100) })
        #expect(value.history(for: .month).count == 31)
        #expect(value.history(for: .month).first?.value == 110)
    }

    @Test func observationsAreSortedAndDuplicatePublicationIsReplaced() {
        let item = MarketSeries(id: "x", name: "x", subtitle: "", category: .markets,
            unit: .usd, source: "Test",
            observations: [MarketObservation(date: date, value: 2),
                           MarketObservation(date: date.addingTimeInterval(-86_400), value: 1),
                           MarketObservation(date: date, value: 3)])
        #expect(item.observations.map(\.value) == [1, 3])
    }

    @Test func continuingAddsToHeldObservationsAndKeepsTheirCompleteness() {
        let held = series([1, 2]).replacing(observations: series([1, 2]).observations, completeHistory: true)
        let received = series([3])
        let result = received.continuing(held)
        #expect(result.observations.map(\.value) == [1, 2, 3])
        #expect(result.hasCompleteHistory)
        #expect(received.continuing(nil).observations.map(\.value) == [3])
    }
}
