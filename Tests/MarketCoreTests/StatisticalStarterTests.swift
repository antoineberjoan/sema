// Vérifie les références de départ des sources statistiques sans fabriquer de série.
import Foundation
import Testing
@testable import MarketCore

struct StatisticalStarterTests {
    @Test func everyPublicSourceHasTwentyUniqueCatalogReferences() {
        for source in StatisticalSource.allCases {
            let values = StatisticalStarter.recommendations(for: source)
            #expect(values.count == 20)
            #expect(Set(values.map(\.id)).count == 20)
            #expect(values.allSatisfy { $0.source == source && !$0.datasetCode.isEmpty && !$0.key.isEmpty && !$0.title.isEmpty })
        }
    }

    @Test func referencesKeepProviderDatasetAndSeriesIdentity() throws {
        let ecb = try #require(StatisticalStarter.recommendations(for: .ecb).first)
        #expect(ecb.datasetCode == "EXR")
        #expect(ecb.key == "D.USD.EUR.SP00.A")
        #expect(ecb.matches(.init(source: .ecb, code: "EXR", agency: "ECB", version: "1.0", title: "Changes", detail: "")))
        #expect(!ecb.matches(.init(source: .bis, code: "EXR", agency: "ECB", version: "1.0", title: "Changes", detail: "")))
        #expect(StatisticalStarter.recommendations(for: .eurostat).contains {
            $0.key == "A.Y15-74.PC_ACT.T.FR"
        })

        let insee = try #require(StatisticalStarter.recommendations(for: .insee).first)
        #expect(insee.datasetCode == "IPC-2025")
        #expect(insee.key == "M.IPC.SO.00.00.INDICE.ENSEMBLE.FE.SO.BRUT.2025.FALSE")

        let fed = StatisticalStarter.recommendations(for: .newYorkFed)
        #expect(fed.contains { $0.datasetCode == "EFFR" && $0.key == "targetRateFrom" })
        #expect(fed.contains { $0.datasetCode == "SOFRAI" && $0.key == "average90day" })

        let worldBank = try #require(StatisticalStarter.recommendations(for: .worldBank).first)
        #expect(worldBank.agency == "2")
        #expect(worldBank.key == "FR")
    }
}
