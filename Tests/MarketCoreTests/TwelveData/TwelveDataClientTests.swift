// Vérifie droits de forfait, identité, précision et refus de Twelve Data, sans clé personnelle ni réseau.
import Foundation
import Testing
@testable import MarketCore

struct TwelveDataClientTests {
    private let item = MarketInstrument(provider: .twelveData, symbol: "AAPL", name: "Apple",
                                        exchange: "NASDAQ", currency: "USD", kind: "Common Stock")
    private var payload: [String: Any] {
        ["meta": ["symbol": "AAPL", "currency": "USD", "exchange": "NASDAQ", "interval": "1day"],
         "values": [["datetime": "2026-10-16", "close": "123.4567890123"],
                    ["datetime": "2026-10-15", "close": "120.10"]]]
    }
    @Test func respectsIndividualAndBusinessFamilies() {
        let access = ["global": "Basic", "plan": "Pro", "plan_business": "Venture"]
        #expect(!TwelveDataMapping.permits(access: access, plan: "basic"))
        #expect(!TwelveDataMapping.permits(access: access, plan: "grow"))
        #expect(TwelveDataMapping.permits(access: access, plan: "pro"))
        #expect(TwelveDataMapping.permits(access: access, plan: "Venture"))
        #expect(!TwelveDataMapping.permits(access: ["plan_business": "Pro"], plan: "venture"))
    }
    @Test func missingOrUnknownRightsAreNotPresentedAsIncluded() {
        #expect(!TwelveDataMapping.permits(access: [:], plan: "ultra"))
        #expect(!TwelveDataMapping.permits(access: ["plan": "Custom"], plan: "ultra"))
        #expect(!TwelveDataMapping.recognizes("Custom"))
    }
    @Test func filtersAndDeduplicatesTwelveInstruments() throws {
        let row: [String: Any] = ["symbol": "AAPL", "name": "Apple", "currency": "USD", "exchange": "NASDAQ",
                                  "type": "Common Stock", "access": ["plan": "Basic"]]
        var excluded = row; excluded["access"] = ["plan": "Pro"]
        let data: [String: Any] = ["count": 3, "data": [row, row, excluded]]
        let items = try TwelveDataMapping.instruments(data, plan: "basic", kind: nil)
        #expect(items.count == 1)
        #expect(items.first?.symbol == "AAPL")
        #expect(items.first?.kind == "Common Stock")
    }
    @Test func refusesPartialCatalogues() {
        #expect(throws: MarketDataError.invalidData) {
            try TwelveDataMapping.instruments(["count": 20, "data": []], plan: "basic", kind: nil)
        }
    }
    @Test func keepsExactDecimalsDatesAndProviderIdentity() throws {
        let value = try TwelveDataMapping.series(payload, instrument: item, now: .now)
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
        #expect(throws: MarketDataError.invalidData) { try TwelveDataMapping.series(data, instrument: item, now: .now) }
    }
    @Test func rejectsTruncatedNumbersAndImpossibleDates() {
        for row in [["datetime": "2026-02-30", "close": "12.2"],
                    ["datetime": "2026-10-16", "close": "12.2garbage"],
                    ["datetime": "2026-10-16", "close": "NaN"]] {
            var data = payload; data["values"] = [row]
            #expect(throws: MarketDataError.invalidData) { try TwelveDataMapping.series(data, instrument: item, now: .now) }
        }
    }
    @Test func weeklyAndDailyHistoriesCannotBeMergedUnderOneID() {
        #expect(item.id != item.usingWeekly(true).id)
        let other = MarketInstrument(provider: .twelveData, symbol: "AAPL", name: "Apple", exchange: "LSE", currency: "USD", kind: "Common Stock")
        #expect(item.id != other.id)
    }
    @Test func doesNotTurnAnETFIntoItsUnderlyingIndex() throws {
        let data: [String: Any] = ["count": 1, "data": [["symbol": "CAC", "name": "Amundi CAC 40", "exchange": "Euronext", "currency": "EUR", "access": ["plan": "Grow"]]]]
        let items = try TwelveDataMapping.instruments(data, plan: "grow", kind: "ETF")
        #expect(items.first?.kind == "ETF")
        #expect(items.first?.displayUnit == "EUR")
    }
    @Test func newOptionalDescriptorPreservesOldCaches() throws {
        let value = try TwelveDataMapping.series(payload, instrument: item, now: .now)
        let encoded = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(MarketSeries.self, from: encoded).marketInstrument == item)
        var old = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        old.removeValue(forKey: "marketInstrument")
        let legacy = try JSONSerialization.data(withJSONObject: old)
        #expect(try JSONDecoder().decode(MarketSeries.self, from: legacy).marketInstrument == nil)
    }
}
