// Vérifie que les repères de départ de Webstat sont lus dans leur fichier JSON, sans changer d'identité.
import Foundation
import Testing
@testable import MarketCore

struct WebstatStarterTests {
    @Test func startersComeFromTheJSONFileWithUniqueIdentities() {
        #expect(WebstatStarter.definitions.count == 16)
        #expect(Set(WebstatStarter.definitions.map(\.id)).count == 16)
        #expect(Set(WebstatStarter.ids).count == 16)
        #expect(WebstatStarter.series.allSatisfy { $0.observations.isEmpty && !$0.name.isEmpty })
    }

    @Test func shortIdentifiersStillOpenTheirSeries() {
        #expect(IdentifierMigration.upgrade("fr10") == "FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD")
        #expect(IdentifierMigration.upgrade("inflation-euro") == "HICP.M.U2.N.000000.4D0.ANR")
        #expect(IdentifierMigration.upgrade("unknown-id") == "unknown-id")
    }
}
