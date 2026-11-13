// Vérifie que les repères de départ de Webstat sont lus dans leur fichier JSON, sans changer d'identité.
import Foundation
import Testing
@testable import MarketCore

struct WebstatStarterTests {
    @Test func startersComeFromTheJSONFileWithUniqueIdentities() {
        #expect(WebstatStarter.definitions.count == 16)
        #expect(Set(WebstatStarter.definitions.map(\.seriesCode)).count == 16)
        #expect(Set(WebstatStarter.ids).count == 16)
        #expect(WebstatStarter.series.allSatisfy { $0.observations.isEmpty && !$0.name.isEmpty })
    }

    @Test func shortIdentifiersStillOpenTheirSeries() {
        #expect(IdentifierMigration.upgrade("fr10") == "FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD")
        #expect(IdentifierMigration.upgrade("inflation-euro") == "HICP.M.U2.N.000000.4D0.ANR")
        #expect(IdentifierMigration.upgrade("unknown-id") == "unknown-id")
    }

    @Test func startersComeFirstInFileOrderThenTheOtherResults() throws {
        func result(_ key: String) throws -> WebstatSeriesDescriptor {
            try WebstatSeriesDescriptor(raw: ["series_key": .string(key), "dataset_id": .string("TEST"), "title_fr": .string(key)])
        }
        let first = try #require(WebstatStarter.definitions.first?.seriesCode)
        let last = try #require(WebstatStarter.definitions.last?.seriesCode)
        let ordered = WebstatStarter.placingFirst([try result("OTHER"), try result(last), try result(first)])
        #expect(ordered.map(\.key) == [first, last, "OTHER"])
    }
}
