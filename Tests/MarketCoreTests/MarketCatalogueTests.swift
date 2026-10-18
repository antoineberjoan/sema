// Vérifie les droits publiés des catalogues et le décodage strict des cotations américaines.
import Foundation
import Testing
@testable import MarketCore

struct MarketCatalogueTests {
    @Test func respectsIndividualAndBusinessFamilies() {
        let access = ["global": "Basic", "plan": "Pro", "plan_business": "Venture"]
        #expect(!MarketCatalogue.permits(access: access, plan: "basic"))
        #expect(!MarketCatalogue.permits(access: access, plan: "grow"))
        #expect(MarketCatalogue.permits(access: access, plan: "pro"))
        #expect(MarketCatalogue.permits(access: access, plan: "Venture"))
        #expect(!MarketCatalogue.permits(access: ["plan_business": "Pro"], plan: "venture"))
    }
    @Test func missingOrUnknownRightsAreNotPresentedAsIncluded() {
        #expect(!MarketCatalogue.permits(access: [:], plan: "ultra"))
        #expect(!MarketCatalogue.permits(access: ["plan": "Custom"], plan: "ultra"))
        #expect(!MarketCatalogue.recognizes("Custom"))
    }
    @Test func filtersAndDeduplicatesTwelveInstruments() throws {
        let row: [String: Any] = ["symbol": "AAPL", "name": "Apple", "currency": "USD", "exchange": "NASDAQ",
                                  "type": "Common Stock", "access": ["plan": "Basic"]]
        var excluded = row; excluded["access"] = ["plan": "Pro"]
        let data: [String: Any] = ["count": 3, "data": [row, row, excluded]]
        let items = try MarketCatalogue.twelve(data, plan: "basic", kind: nil)
        #expect(items.count == 1)
        #expect(items.first?.symbol == "AAPL")
        #expect(items.first?.kind == "Common Stock")
    }
    @Test func refusesPartialCatalogues() {
        #expect(throws: MarketDataError.invalidData) {
            try MarketCatalogue.twelve(["count": 20, "data": []], plan: "basic", kind: nil)
        }
    }
    @Test func parsesQuotedCSVWithoutInventingAnIndex() throws {
        let body = Data(("\u{FEFF}symbol,name,exchange,assetType,ipoDate,delistingDate,status\r\n" +
            "AAPL,\"Apple, Inc.\",NASDAQ,Stock,1980-12-12,null,Active\r\n" +
            "SPY,\"SPDR \"\"S&P\"\" 500\",NYSE ARCA,ETF,1993-01-29,null,Active\r\n" +
            "OLD,Old company,NYSE,Stock,1980-01-01,2020-01-01,Delisted\r\n").utf8)
        let items = try MarketCatalogue.alpha(body)
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
            #expect(throws: MarketDataError.invalidData) { try MarketCatalogue.alpha(Data(text.utf8)) }
        }
    }
    @Test func startersComeFromTheCatalogueOnly() {
        func item(_ symbol: String, _ currency: String = "USD") -> MarketInstrument {
            MarketInstrument(provider: .twelveData, symbol: symbol, name: symbol, exchange: "X", currency: currency, kind: "ETF")
        }
        let catalogue = MarketCatalogue(instruments: [item("MSFT"), item("SPY", "EUR"), item("SPY"), item("ZZZ")], scope: "")
        #expect(catalogue.starters.map(\.symbol) == ["SPY", "MSFT"])
        #expect(catalogue.starters.first?.currency == "USD")
    }
}
