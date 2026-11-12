// Vérifie la découverte des mesures de la Fed de New York et leur décodage, sans réseau.
import Foundation
import Testing
@testable import MarketCore

struct NewYorkFedClientTests {
    @Test func discoversFedMeasuresInsteadOfConflatingTargetRateAndEffectiveRate() throws {
        let json = Data("""
        {"refRates":[{"type":"EFFR","effectiveDate":"2025-01-02","percentRate":4.33,"targetRateFrom":4.25,"targetRateTo":4.50,"volumeInBillions":100}]}
        """.utf8)
        let flows = try NewYorkFedMapping.datasets(json)
        let flow = try #require(flows.first)
        #expect(flow.metadata["MEASURE:targetRateFrom"] != nil)
        let target = try NewYorkFedMapping.series(json, dataset: flow, key: "targetRateFrom", fullHistory: false, now: .now)
        let effective = try NewYorkFedMapping.series(json, dataset: flow, key: "percentRate", fullHistory: false, now: .now)
        #expect(target.id != effective.id)
        #expect(target.latest?.value == Decimal(string: "4.25"))
        #expect(effective.latest?.value == Decimal(string: "4.33"))
    }
    @Test func listsMeasuresWithoutInventingCombinations() async throws {
        let flow = StatisticalDataset(source: .newYorkFed, code: "TEST", agency: "SOURCE", version: "1", title: "Indicateur", detail: "")
        let dimension = StatisticalDimension(id: "MEASURE", title: "Choix", position: 1, codes: [.init(id: "targetRateFrom", title: "Libellé publié")])
        let structure = StatisticalStructure(dimensions: [dimension], labels: [:])
        let items = try await NewYorkFedClient().seriesCatalogue(dataset: flow, structure: structure)
        #expect(items.count == 1 && items[0].key == "targetRateFrom")
        #expect(items[0].title == "Indicateur · Libellé publié")
        #expect(items[0].series(observations: []).observations.isEmpty)
    }
}
