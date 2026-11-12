// Vérifie la pagination de la recherche Webstat et le passage à l’export allégé au-delà de la limite de l’API.
import Foundation
import Testing
@testable import MarketCore

struct WebstatPagingTests {
    @Test func pagesHoldFiftyResultsAndTheLastPermittedOffsetIs9950() {
        #expect(WebstatClient.pageSize == 50)
        #expect(WebstatClient.maximumSearchOffset == 9_950)
        #expect(WebstatClient.maximumSearchOffset % WebstatClient.pageSize == 0)
        // The API refuses an offset beyond 10 000: the last full page starts at 9 950.
        #expect(WebstatClient.maximumSearchOffset + WebstatClient.pageSize == 10_000)
    }

    @Test func theSearchSwitchesToTheExportFromTheLastPermittedOffset() {
        #expect(!WebstatClient.usesSummaryExport(forOffset: 0))
        #expect(!WebstatClient.usesSummaryExport(forOffset: 9_900))
        #expect(WebstatClient.usesSummaryExport(forOffset: 9_950))
        #expect(WebstatClient.usesSummaryExport(forOffset: 10_000))
    }
}
