// Vérifie le catalogue CSV et les clôtures hebdomadaires d'Alpha Vantage, sans clé personnelle ni réseau.
import Foundation
import Testing
@testable import MarketCore

struct AlphaVantageClientTests {
    @Test func parsesQuotedCSVWithoutInventingAnIndex() throws {
        let body = Data(("\u{FEFF}symbol,name,exchange,assetType,ipoDate,delistingDate,status\r\n" +
            "AAPL,\"Apple, Inc.\",NASDAQ,Stock,1980-12-12,null,Active\r\n" +
            "SPY,\"SPDR \"\"S&P\"\" 500\",NYSE ARCA,ETF,1993-01-29,null,Active\r\n" +
            "OLD,Old company,NYSE,Stock,1980-01-01,2020-01-01,Delisted\r\n").utf8)
        let items = try AlphaVantageMapping.instruments(body)
        #expect(items.count == 2)
        #expect(items[0].name == "Apple, Inc.")
        #expect(items[1].name == "SPDR \"S&P\" 500")
        #expect(items[1].kind == "ETF")
        #expect(items[1].displayUnit == "USD")
    }
    @Test func rejectsTruncatedCSVAndJSONQuotaResponses() {
        for text in ["symbol,name,exchange,assetType,status\nAAPL,\"Apple,NASDAQ,Stock,Active",
                     "symbol,name,exchange,assetType,status\nAAPL,Apple",
                     "{\"Information\":\"quota\"}"] {
            #expect(throws: MarketDataError.invalidData) { try AlphaVantageMapping.instruments(Data(text.utf8)) }
        }
    }
    @Test func decodesAlphaWeeklyClosesWithNoDailyInterpolation() throws {
        let instrument = MarketInstrument(provider: .alphaVantage, symbol: "IBM", name: "IBM", exchange: "United States", currency: "USD", kind: "Equity", weekly: true)
        let data: [String: Any] = ["Meta Data": ["2. Symbol": "IBM"], "Weekly Time Series": ["2026-10-16": ["4. close": "250.1234"], "2026-10-09": ["4. close": "248.1000"]]]
        let value = try AlphaVantageMapping.series(data, instrument: instrument, now: .now)
        #expect(value.frequency == .weekly)
        #expect(value.observations.count == 2)
        #expect(value.latest?.value == Decimal(string: "250.1234"))
        #expect(value.hasCompleteHistory == false)
    }
}
