// Vérifie l’ordre des lignes de l’agenda, ses trois lignes d’abord et la semaine ouvrée.
import Foundation
import Testing
@testable import MarketCore

struct DayAgendaTests {
    private let start = Date(timeIntervalSince1970: 1_792_022_400)

    private func series(_ id: String, last: Decimal, fred: String? = nil) -> MarketSeries {
        var values: [Decimal] = [100]
        for index in 0..<UnusualMove.window { values.append(values[values.count - 1] * (index.isMultiple(of: 2) ? 1.01 : 0.99)) }
        values.append(values[values.count - 1] * (1 + last / 100))
        let descriptor = fred.map {
            StatisticalSeriesDescriptor(dataset: .init(source: .fred, code: $0, agency: "FRED", version: "1", title: "Release", detail: ""),
                                        key: id, dimensionIDs: [], fields: [:], labels: [:])
        }
        return MarketSeries(id: id, name: id, subtitle: "Fixture", category: .markets, unit: .number, source: "Test",
                            observations: values.enumerated().map {
            MarketObservation(date: start.addingTimeInterval(Double($0.offset) * .day), value: $0.element)
        }, statisticalDescriptor: descriptor)
    }

    private func utc(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

    private func parisCalendar() -> Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }

    @Test func linesFollowTheImportanceOrder() throws {
        let big = series("big", last: -5), calm = series("calm", last: 0.2), followed = series("rates", last: 0.1, fred: "18")
        let day = try #require(big.latest?.date)
        let release = EconomicRelease(releaseID: "17", name: "Taux de change", date: day)
        let followedRelease = EconomicRelease(releaseID: "18", name: "Taux d’intérêt", date: day)
        let press = PressRelease(feed: .fed, title: "Communiqué", link: URL(string: "https://example.com/p")!, publishedAt: day)
        let headline = Headline(title: "Titre", link: URL(string: "https://example.com/h")!, publisher: "example.com", publishedAt: day)
        let agenda = DayAgenda(day: day, series: [calm, big, followed], sensitivity: .normal,
                               releases: [release, followedRelease], pressReleases: [press], headlines: [headline])
        #expect(agenda.items.map(\.id) == ["move:big", "release:\(followedRelease.id)", "release:\(release.id)", "press:\(press.id)", "headline:\(headline.id)"])
        #expect(agenda.shown.count == DayAgenda.shownLimit)
        #expect(agenda.hiddenCount == 2)
    }

    @Test func aCalmDayHasNoMoveAndNoHiddenLine() throws {
        let calm = series("calm", last: 0.2)
        let day = try #require(calm.latest?.date)
        let agenda = DayAgenda(day: day, series: [calm], sensitivity: .normal, releases: [], pressReleases: [], headlines: [])
        #expect(agenda.items.isEmpty)
        #expect(agenda.hiddenCount == 0)
        #expect(!DayAgenda.hasUnusualMove(on: day, series: [calm], sensitivity: .normal))
        #expect(DayAgenda.hasUnusualMove(on: day, series: [series("big", last: -5)], sensitivity: .normal))
    }

    @Test func weekRunsFromMondayToFridayAtNoonUTC() {
        let thursday = utc("2026-11-05T21:31:00Z")
        let week = DayAgenda.week(containing: thursday, calendar: parisCalendar())
        #expect(week == ["2026-11-02", "2026-11-03", "2026-11-04", "2026-11-05", "2026-11-06"].map { utc($0 + "T12:00:00Z") })
        #expect(DayAgenda.currentDay(now: thursday, calendar: parisCalendar()) == utc("2026-11-05T12:00:00Z"))
    }

    @Test func weekendOpensOnFriday() {
        let saturday = utc("2026-11-07T10:00:00Z")
        #expect(DayAgenda.currentDay(now: saturday, calendar: parisCalendar()) == utc("2026-11-06T12:00:00Z"))
    }
}
