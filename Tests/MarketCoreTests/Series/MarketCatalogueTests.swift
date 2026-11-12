// Vérifie les valeurs de départ proposées par un catalogue de cours, fournisseur par fournisseur.
import Foundation
import Testing
@testable import MarketCore

struct MarketCatalogueTests {
    @Test func popularStartersAreConsistentAcrossMarketProviders() {
        let expected = ["AAPL", "MSFT", "NVDA", "TSLA", "GOOGL", "AMZN", "META", "JPM", "V", "MA",
                        "WMT", "COST", "NFLX", "AVGO", "AMD", "ORCL", "LLY", "XOM", "SPY", "QQQ"]
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
    @Test func twelveDataUsesDirectIndicesWhenTheirActualCatalogueContainsThem() {
        let stocks = ["AAPL", "MSFT", "NVDA", "TSLA", "GOOGL", "AMZN", "META", "JPM", "V", "MA",
                      "WMT", "COST", "NFLX", "AVGO", "AMD", "ORCL", "LLY", "XOM"].map { symbol in
            MarketInstrument(provider: .twelveData, symbol: symbol, name: symbol, exchange: "X", currency: "USD", kind: "Common Stock")
        }
        func item(_ symbol: String, _ name: String, _ currency: String, _ kind: String) -> MarketInstrument {
            MarketInstrument(provider: .twelveData, symbol: symbol, name: name, exchange: "X", currency: currency, kind: kind)
        }
        let direct = MarketCatalogue(instruments: stocks + [
            item("SPX", "S&P 500", "USD", "Index"), item("FCHI", "CAC 40", "EUR", "Index"),
            item("SPY", "SPDR S&P 500 ETF Trust", "USD", "ETF"), item("QQQ", "Invesco QQQ Trust", "USD", "ETF")
        ], scope: "")
        #expect(direct.starters.count == 20)
        #expect(Array(direct.starters.suffix(2)).map(\.symbol) == ["SPX", "FCHI"])
        #expect(Array(direct.starters.suffix(2)).allSatisfy { $0.kind == "Index" })

        let unverified = MarketCatalogue(instruments: stocks + [
            item("SPX", "S&P 500 ETF", "USD", "ETF"), item("FCHI", "CAC 40 tracker", "EUR", "ETF"),
            item("SPY", "SPDR S&P 500 ETF Trust", "USD", "ETF"), item("QQQ", "Invesco QQQ Trust", "USD", "ETF")
        ], scope: "")
        #expect(Array(unverified.starters.suffix(2)).map(\.symbol) == ["SPY", "QQQ"])
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
