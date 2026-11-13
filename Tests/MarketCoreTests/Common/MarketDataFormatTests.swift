// Vérifie que les erreurs des fournisseurs de cours sont reconnues même avec un code HTTP 200.
import Foundation
import Testing
@testable import MarketCore

struct MarketDataFormatTests {
    @Test func recognizesErrorsEvenWithHTTP200() {
        #expect(throws: MarketDataError.quota) { try MarketDataFormat.checkError(["Information": "Our rate limit is 25 requests per day."]) }
        #expect(throws: MarketDataError.entitlement) { try MarketDataFormat.checkError(["Information": "This is a premium endpoint."]) }
        #expect(throws: MarketDataError.invalidKey) { try MarketDataFormat.checkError(["code": 401, "message": "incorrect apikey"]) }
    }

    @Test func onlyQuotaAndRejectedKeyStopAProvider() {
        #expect(MarketDataError.quota.stopsProvider)
        #expect(MarketDataError.invalidKey.stopsProvider)
        #expect(!MarketDataError.unavailable.stopsProvider)
        #expect(!MarketDataError.network.stopsProvider)
    }
}
