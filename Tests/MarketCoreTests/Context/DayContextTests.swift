// Vérifie les repères liés d’une séance, la fenêtre du jour et la lecture du calendrier FRED.
import Foundation
import Testing
@testable import MarketCore

struct DayContextTests {
    private let start = Date(timeIntervalSince1970: 1_792_022_400)

    private func series(_ id: String, unit: ValueUnit = .number, last: Decimal) -> MarketSeries {
        var values: [Decimal] = [100]
        for index in 0..<UnusualMove.window { values.append(values[values.count - 1] * (index.isMultiple(of: 2) ? 1.01 : 0.99)) }
        values.append(values[values.count - 1] * (1 + last / 100))
        return MarketSeries(id: id, name: id, subtitle: "Fixture", category: .markets, unit: unit, source: "Test",
                            observations: values.enumerated().map {
            MarketObservation(date: start.addingTimeInterval(Double($0.offset) * .day), value: $0.element)
        })
    }

    @Test func peersOfTheSameDayAreOrderedByDistanceFromTheUsual() throws {
        let spy = series("spy", last: -4)
        let qqq = series("qqq", last: -5.5)
        let calm = series("calm", last: 0.3)
        let day = try #require(spy.latest?.date)
        let peers = PeerMove.moves(on: day, among: [spy, calm, qqq], excluding: "spy")
        #expect(peers.map(\.id) == ["qqq", "calm"])
        #expect(peers.first.map { $0.change < -5.4 } == true)
    }

    @Test func sessionWindowCoversTheWholeUTCDay() {
        let window = DayContext.window(for: ISO8601DateFormatter().date(from: "2026-11-05T21:20:00Z")!)
        #expect(window.start == ISO8601DateFormatter().date(from: "2026-11-05T00:00:00Z"))
        #expect(window.end == ISO8601DateFormatter().date(from: "2026-11-05T23:59:59Z"))
    }

    @Test func fredCalendarListsTheReleasesOfTheDay() throws {
        let data = Data(#"{"release_dates":[{"release_id":180,"release_name":"Unemployment Insurance Weekly Claims Report","date":"2026-11-05"}]}"#.utf8)
        let releases = try FredMapping.releaseDates(data)
        #expect(releases.map(\.name) == ["Unemployment Insurance Weekly Claims Report"])
        #expect(!FredClient.releaseDatesRequest(on: start).url!.absoluteString.contains("api_key"))
    }
}
