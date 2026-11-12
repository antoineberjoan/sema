// Vérifie le catalogue de séries de la Banque mondiale, sans réseau.
import Foundation
import Testing
@testable import MarketCore

struct WorldBankClientTests {
    @Test func listsCountriesWithoutInventingCombinations() async throws {
        let flow = StatisticalDataset(source: .worldBank, code: "TEST", agency: "SOURCE", version: "1", title: "Indicateur", detail: "")
        let dimension = StatisticalDimension(id: "REF_AREA", title: "Choix", position: 1, codes: [.init(id: "FR", title: "Libellé publié")])
        let structure = StatisticalStructure(dimensions: [dimension], labels: [:])
        let items = try await WorldBankClient().seriesCatalogue(dataset: flow, structure: structure)
        #expect(items.count == 1 && items[0].key == "FR")
        #expect(items[0].title == "Indicateur · Libellé publié")
        #expect(items[0].series(observations: []).observations.isEmpty)
    }
}
