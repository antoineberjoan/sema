import Foundation
import Testing
@testable import MarketCore

struct HalfYearHistoryTests {
    @Test(arguments: [ObservationFrequency.daily, .monthly])
    func sixMonthsUsesCalendarBoundaryAndKeepsRateUnits(frequency: ObservationFrequency) {
        let formatter = ISO8601DateFormatter()
        func date(_ day: String) -> Date { formatter.date(from: day + "T00:00:00Z")! }
        let series = MarketSeries(id: "fixture-rate", name: "Taux", subtitle: "", category: .markets,
            unit: .percent, source: "Fixture", isDemo: true, frequency: frequency,
            observations: [
                MarketObservation(date: date("2024-01-30"), value: 2),
                MarketObservation(date: date("2024-01-31"), value: 3),
                MarketObservation(date: date("2024-07-31"), value: 4)
            ])

        #expect(series.supports(.halfYear))
        #expect(series.history(for: .halfYear).map(\.value) == [3, 4])
        #expect(series.change(for: .halfYear) == 1)
        #expect(!series.supports(.year))
    }
}
