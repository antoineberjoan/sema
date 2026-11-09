// Résultats de la recherche rapide : les favoris d’abord, puis les autres repères locaux.
import Foundation
import MarketCore

extension AppStore {
    func searchResults(for query: String) -> [MarketSeries] {
        SeriesSearch.results(in: favorites + macroSeries.filter { !isFavorite($0.id) }, query: query)
    }
}
