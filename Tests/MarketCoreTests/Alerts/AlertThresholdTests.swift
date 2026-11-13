// Vérifie la lecture d'un seuil saisi : décimales françaises acceptées, valeurs partielles ou hors bornes refusées.
import Foundation
import Testing
@testable import MarketCore

struct AlertThresholdTests {
    @Test func thresholdAcceptsFrenchDecimalsAndRejectsPartialOrInvalidValues() {
        #expect(AlertThreshold.parse("2,5") == Decimal(string: "2.5")!)
        #expect(AlertThreshold.parse(" 2.50 ") == Decimal(string: "2.5")!)
        for input in ["", "0", "-2", "101", "2foo", "NaN", "2,5,6", "1e2"] {
            #expect(AlertThreshold.parse(input) == nil)
        }
    }
}
