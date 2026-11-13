// Vérifie la pagination de la recherche Webstat et le passage à l’export allégé au-delà de la limite de l’API.
import Foundation
import Testing
@testable import MarketCore

struct WebstatPagingTests {
    @Test func pagesHoldFiftyResultsAndTheLastPermittedOffsetIs9950() {
        #expect(WebstatClient.pageSize == 50)
        #expect(WebstatClient.maximumSearchOffset == 9_950)
        #expect(WebstatClient.maximumSearchOffset % WebstatClient.pageSize == 0)
        // L’API refuse un décalage au-delà de 10 000 : la dernière page pleine commence à 9 950.
        #expect(WebstatClient.maximumSearchOffset + WebstatClient.pageSize == 10_000)
    }

    @Test func theSearchSwitchesToTheExportFromTheLastPermittedOffset() {
        #expect(!WebstatClient.usesSummaryExport(forOffset: 0))
        #expect(!WebstatClient.usesSummaryExport(forOffset: 9_900))
        #expect(WebstatClient.usesSummaryExport(forOffset: 9_950))
        #expect(WebstatClient.usesSummaryExport(forOffset: 10_000))
    }

    @Test func aSliceOfTheExportIsAPageWithItsTotal() {
        let all = Array(0..<120)
        let second = WebstatPage<Int>.slice(of: all, offset: 50, size: 50)
        #expect(second.items == Array(50..<100))
        #expect(second.total == 120)
        #expect(second.hasMore)
        let last = WebstatPage<Int>.slice(of: all, offset: 100, size: 50)
        #expect(last.items.count == 20)
        #expect(!last.hasMore)
        #expect(WebstatPage<Int>.slice(of: all, offset: 150, size: 50).items.isEmpty)
    }
}
