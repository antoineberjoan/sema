// Vérifie que la recherche locale lit les mots-clés d'un repère de départ par son code de série.
import Foundation
import Testing
@testable import MarketCore

struct SeriesSearchTests {
    private func series(id: String) -> MarketSeries {
        MarketSeries(id: id, name: "Taux", subtitle: "Fixture", category: .markets, unit: .percent, source: "Fixture", observations: [])
    }

    @Test func aStarterKeywordIsFoundThroughTheSeriesCode() {
        let known = series(id: "FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD")
        let other = series(id: "CUSTOM.M.FR.SERIES")
        let found = SeriesSearch.results(in: [known, other], query: "emprunt phare")
        #expect(found.map(\.id) == [known.id])
    }
}
