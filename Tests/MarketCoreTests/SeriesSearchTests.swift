import Foundation
import Testing
@testable import MarketCore

struct SeriesSearchTests {
    @Test func findsAnIntegratedRateByItsUsualName() {
        let items = DemoCatalog.series()
        #expect(SeriesSearch.results(in: items, query: "OAT").map(\.id) == ["fr10"])
        #expect(SeriesSearch.results(in: items, query: "bce depot").map(\.id) == ["ecb"])
        #expect(SeriesSearch.results(in: items, query: "épargne populaire").map(\.id) == ["lep"])
    }

    @Test func combinesWordsAndIgnoresCaseAccentsAndPunctuation() {
        let items = DemoCatalog.series()
        #expect(SeriesSearch.results(in: items, query: "  EURO / DOLLAR ").map(\.id) == ["eurusd"])
        #expect(SeriesSearch.results(in: items, query: "france inflation").map(\.id) == ["inflation"])
        #expect(SeriesSearch.results(in: items, query: "euro inflation").isEmpty)
    }

    @Test func emptyQueryKeepsCallerOrderAndExcludesFunds() {
        let items = DemoCatalog.series().reversed().map { $0 }
        #expect(SeriesSearch.results(in: items, query: "  ").map(\.id) == items.filter { $0.category != .funds }.map(\.id))
        #expect(SeriesSearch.results(in: items, query: "Atlas").isEmpty)
        #expect(SeriesSearch.results(in: items, query: "TEC10").isEmpty)
        #expect(SeriesSearch.results(in: items, query: "Nvidia").isEmpty)
    }
}
