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
    @Test func popularStartersAreConsistentAcrossMarketProviders() {
        let expected = ["AAPL", "MSFT", "NVDA", "TSLA", "SPY", "QQQ", "GOOGL", "AMZN", "META", "JPM",
                        "V", "MA", "WMT", "COST", "NFLX", "AVGO", "AMD", "ORCL", "LLY", "XOM"]
        for provider in MarketProvider.allCases {
            let items = expected.map { symbol in
                MarketInstrument(provider: provider, symbol: symbol, name: symbol, exchange: "X", currency: "USD",
                                 kind: ["SPY", "QQQ"].contains(symbol) ? "ETF" : (provider == .alphaVantage ? "Stock" : "Common Stock"))
            }
            let catalogue = MarketCatalogue(instruments: items, scope: "")
            #expect(catalogue.starters.map(\.symbol) == expected)
            #expect(catalogue.starters.filter { $0.kind == "ETF" }.map(\.symbol) == ["SPY", "QQQ"])
            #expect(catalogue.starters.allSatisfy { $0.provider == provider && $0.currency == "USD" })
        }
    }
    @Test func startersStayWithinTheMatchingCatalogueAndAssetType() {
        func item(_ provider: MarketProvider = .twelveData, _ symbol: String, _ currency: String = "USD", _ kind: String = "Common Stock", _ exchange: String = "X") -> MarketInstrument {
            MarketInstrument(provider: provider, symbol: symbol, name: symbol, exchange: exchange, currency: currency, kind: kind)
        }
        let catalogue = MarketCatalogue(instruments: [
            item(.twelveData, "AAPL", "USD", "ETF"),
            item(.twelveData, "AAPL", "EUR"),
            item(.twelveData, "MSFT"),
            item(.twelveData, "SPY", "USD", "ETF"),
            item(.twelveData, "QQQ", "USD", "Common Stock"),
            item(.alphaVantage, "NVDA", "USD", "Stock"),
            item(.twelveData, "ZZZ")
        ], scope: "")
        #expect(catalogue.starters.map(\.symbol) == ["MSFT", "SPY"])
    }
}
