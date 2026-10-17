// Vérifie identité, précision, cache et refus fournisseurs sans clé personnelle ni réseau.
import Foundation
import Testing
@testable import MarketCore

struct MarketDataClientTests {
    private let item = MarketInstrument(provider: .twelveData, symbol: "AAPL", name: "Apple",
                                        exchange: "NASDAQ", currency: "USD", kind: "Common Stock")
    private var payload: [String: Any] {
        ["meta": ["symbol": "AAPL", "currency": "USD", "exchange": "NASDAQ", "interval": "1day"],
         "values": [["datetime": "2026-10-16", "close": "123.4567890123"],
                    ["datetime": "2026-10-15", "close": "120.10"]]]
    }
    @Test func keepsExactDecimalsDatesAndProviderIdentity() throws {
        let value = try MarketDataClient.decodeSeries(payload, instrument: item, now: .now)
        #expect(value.latest?.value == Decimal(string: "123.4567890123"))
        #expect(value.fractionDigits == 2)
        #expect(value.observations.count == 2)
        #expect(value.originBadge == "Twelve Data")
        #expect(value.displayUnit == "USD")
        #expect(value.marketInstrument == item)
        #expect(value.replacing(observations: value.observations).marketInstrument == item)
        #expect(value.withID(value.id).marketInstrument == item)
    }
    @Test func rejectsWrongCurrencyAndSymbolInsteadOfChangingAnAlertUnit() {
        var data = payload
        data["meta"] = ["symbol": "AAPL", "currency": "EUR", "exchange": "NASDAQ", "interval": "1day"]
        #expect(throws: MarketDataError.invalidData) { try MarketDataClient.decodeSeries(data, instrument: item, now: .now) }
    }
    @Test func rejectsTruncatedNumbersAndImpossibleDates() {
        for row in [["datetime": "2026-02-30", "close": "12.2"],
                    ["datetime": "2026-10-16", "close": "12.2garbage"],
                    ["datetime": "2026-10-16", "close": "NaN"]] {
            var data = payload; data["values"] = [row]
            #expect(throws: MarketDataError.invalidData) { try MarketDataClient.decodeSeries(data, instrument: item, now: .now) }
        }
    }
    @Test func weeklyAndDailyHistoriesCannotBeMergedUnderOneID() {
        #expect(item.id != item.usingWeekly(true).id)
        let other = MarketInstrument(provider: .twelveData, symbol: "AAPL", name: "Apple", exchange: "LSE", currency: "USD", kind: "Common Stock")
        #expect(item.id != other.id)
    }
    @Test func doesNotTurnAnETFIntoItsUnderlyingIndex() throws {
        let data: [String: Any] = ["count": 1, "data": [["symbol": "CAC", "name": "Amundi CAC 40", "exchange": "Euronext", "currency": "EUR", "access": ["plan": "Grow"]]]]
        let items = try MarketCatalogue.twelve(data, plan: "grow", kind: "ETF")
        #expect(items.first?.kind == "ETF")
        #expect(items.first?.displayUnit == "EUR")
    }
    @Test func decodesAlphaWeeklyClosesWithNoDailyInterpolation() throws {
        let instrument = MarketInstrument(provider: .alphaVantage, symbol: "IBM", name: "IBM", exchange: "United States", currency: "USD", kind: "Equity", weekly: true)
        let data: [String: Any] = ["Meta Data": ["2. Symbol": "IBM"], "Weekly Time Series": ["2026-10-16": ["4. close": "250.1234"], "2026-10-09": ["4. close": "248.1000"]]]
        let value = try MarketDataClient.decodeSeries(data, instrument: instrument, now: .now)
        #expect(value.frequency == .weekly)
        #expect(value.observations.count == 2)
        #expect(value.latest?.value == Decimal(string: "250.1234"))
        #expect(value.hasCompleteHistory == false)
    }
    @Test func recognizesErrorsEvenWithHTTP200() {
        #expect(throws: MarketDataError.quota) { try MarketDataClient.checkError(["Information": "Our rate limit is 25 requests per day."]) }
        #expect(throws: MarketDataError.entitlement) { try MarketDataClient.checkError(["Information": "This is a premium endpoint."]) }
        #expect(throws: MarketDataError.invalidKey) { try MarketDataClient.checkError(["code": 401, "message": "incorrect apikey"]) }
    }
    @Test func newOptionalDescriptorPreservesOldCaches() throws {
        let value = try MarketDataClient.decodeSeries(payload, instrument: item, now: .now)
        let encoded = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(MarketSeries.self, from: encoded).marketInstrument == item)
        var old = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        old.removeValue(forKey: "marketInstrument")
        let legacy = try JSONSerialization.data(withJSONObject: old)
        #expect(try JSONDecoder().decode(MarketSeries.self, from: legacy).marketInstrument == nil)
    }
}
