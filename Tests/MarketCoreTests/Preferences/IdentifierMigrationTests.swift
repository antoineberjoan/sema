// Vérifie que les noms de départ enregistrés deviennent des codes de série et que le reste ne change pas.
import Testing
@testable import MarketCore

struct IdentifierMigrationTests {
    @Test func aStarterSlugBecomesItsSeriesCode() {
        #expect(IdentifierMigration.upgrade("fr10") == "FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD")
    }

    @Test func aSeriesCodeAndAnUnknownIdentifierStayAsTheyAre() {
        let code = "FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD"
        #expect(IdentifierMigration.upgrade(code) == code)
        #expect(IdentifierMigration.upgrade("unknown-id") == "unknown-id")
    }
}
