// Vérifie le découpage de l’historique ancien en tranches de six années, de la plus récente à la plus ancienne.
import Foundation
import Testing
@testable import MarketCore

struct HistoryTrancheTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    private func date(_ day: String) -> Date { ISO8601DateFormatter().date(from: day + "T00:00:00Z")! }

    @Test func aTrancheCoversSixCalendarYears() {
        #expect(HistoryPeriod.recentYears == 6)
        let tranche = HistoryPeriod.tranche(endingAt: date("2026-11-12"), calendar: calendar)
        #expect(tranche.start == date("2020-11-12"))
        #expect(tranche.end == date("2026-11-12"))
        #expect(!tranche.isComplete)
    }

    @Test func aTrancheNeverStartsBeforeThePublishedHistory() {
        let first = date("2023-03-01")
        let tranche = HistoryPeriod.tranche(endingAt: date("2026-11-12"), notBefore: first, calendar: calendar)
        #expect(tranche.start == first)
        #expect(tranche.isComplete)
    }

    @Test func olderTranchesChainBackwardsUntilTheFirstPublishedDate() {
        let first = date("2005-01-01")
        var end = date("2026-11-12")
        var starts: [Date] = []
        while true {
            let tranche = HistoryPeriod.tranche(endingAt: end, notBefore: first, calendar: calendar)
            starts.append(tranche.start)
            if tranche.isComplete { break }
            end = HistoryPeriod.previousEnd(before: tranche.start)
        }
        #expect(starts == [date("2020-11-12"), date("2014-11-11"), date("2008-11-10"), first])
    }

    @Test func theNextTrancheEndsTheDayBeforeTheCurrentOneStarts() {
        #expect(HistoryPeriod.previousEnd(before: date("2020-11-12")) == date("2020-11-11"))
    }

    @Test func aTrancheThatStartsExactlyOnTheFirstDateIsComplete() {
        let tranche = HistoryPeriod.tranche(endingAt: date("2026-11-12"), notBefore: date("2020-11-12"), calendar: calendar)
        #expect(tranche.start == date("2020-11-12"))
        #expect(tranche.isComplete)
    }

    @Test func recentWindowIsCompleteOnlyWhenThePublishedStartFitsInside() {
        let end = date("2026-11-12")
        let inside = HistoryPeriod.recent(endingAt: end, firstPublished: date("2022-01-01"), calendar: calendar)
        #expect(inside.start == date("2020-11-12"))
        #expect(inside.isComplete)
        #expect(!HistoryPeriod.recent(endingAt: end, firstPublished: date("2000-01-01"), calendar: calendar).isComplete)
        #expect(!HistoryPeriod.recent(endingAt: end, firstPublished: nil, calendar: calendar).isComplete)
    }
}
