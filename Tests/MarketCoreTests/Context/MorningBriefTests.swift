// Vérifie l’heure du brief du matin (jours ouvrés, réveil, un envoi par jour) et sa composition.
import Foundation
import Testing
@testable import MarketCore

struct MorningBriefTests {
    private var paris: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }

    private func local(_ text: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = .posix
        formatter.timeZone = TimeZone(identifier: "Europe/Paris")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: text)!
    }

    private var enabled: BriefPreferences {
        var value = BriefPreferences()
        value.isEnabled = true
        return value
    }

    @Test func briefIsDueOncePerWeekdayAfterItsTime() {
        var brief = enabled
        #expect(!brief.isDue(now: local("2026-11-05 07:59"), calendar: paris))
        #expect(brief.isDue(now: local("2026-11-05 08:01"), calendar: paris))
        #expect(brief.isDue(now: local("2026-11-05 14:30"), calendar: paris))
        brief.lastSentAt = local("2026-11-05 08:02")
        #expect(!brief.isDue(now: local("2026-11-05 14:30"), calendar: paris))
        #expect(brief.isDue(now: local("2026-11-06 08:00"), calendar: paris))
        #expect(!BriefPreferences().isDue(now: local("2026-11-05 09:00"), calendar: paris))
    }

    @Test func weekendsWaitForMondayUnlessEveryDayIsChosen() {
        var brief = enabled
        #expect(!brief.isDue(now: local("2026-11-07 09:00"), calendar: paris))
        #expect(brief.next(after: local("2026-11-06 09:00"), calendar: paris) == local("2026-11-09 08:00"))
        brief.isWeekdaysOnly = false
        #expect(brief.next(after: local("2026-11-06 09:00"), calendar: paris) == local("2026-11-07 08:00"))
        #expect(BriefPreferences().next(after: local("2026-11-06 09:00"), calendar: paris) == nil)
    }

    @Test func briefKeepsUnusualMovesAndCloseThresholds() throws {
        let start = Date(timeIntervalSince1970: 1_792_022_400)
        func series(_ id: String, last: Decimal) -> MarketSeries {
            var values: [Decimal] = [100]
            for index in 0..<UnusualMove.window { values.append(values[values.count - 1] * (index.isMultiple(of: 2) ? 1.01 : 0.99)) }
            values.append(values[values.count - 1] * (1 + last / 100))
            return MarketSeries(id: id, name: id, subtitle: "Fixture", category: .markets, unit: .number, source: "Test",
                                observations: values.enumerated().map {
                MarketObservation(date: start.addingTimeInterval(Double($0.offset) * .day), value: $0.element)
            })
        }
        let spy = series("spy", last: -4), calm = series("calm", last: 0.2)
        let latest = try #require(calm.latest)
        let near = AlertRule(seriesID: "calm", direction: .rise, threshold: latest.value * 1.01, condition: .level)
        let far = AlertRule(seriesID: "calm", direction: .rise, threshold: latest.value * 1.2, condition: .level)
        let crossed = AlertRule(seriesID: "calm", direction: .fall, threshold: latest.value * 1.01, condition: .level)
        let now = latest.date.addingTimeInterval(.day / 2)
        let brief = MorningBrief(series: [spy, calm], alerts: [near, far, crossed], sensitivity: .normal, now: now)
        #expect(brief.moves.map(\.id) == ["spy"])
        #expect(brief.nearThresholds.map(\.id) == [near.id])
        #expect(!brief.isQuiet)
        let stale = MorningBrief(series: [spy], alerts: [], sensitivity: .normal, now: now.addingTimeInterval(10 * .day))
        #expect(stale.isQuiet)
    }

    @Test func briefIsOffByDefault() {
        #expect(AppPreferences().brief == nil)
        #expect(BriefPreferences().hour == 8 && BriefPreferences().isWeekdaysOnly)
    }
}
