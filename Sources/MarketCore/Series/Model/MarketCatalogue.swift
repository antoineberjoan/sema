// Porte le catalogue navigable, filtré par forfait quand le fournisseur publie ce contrat.
import Foundation

public struct MarketCatalogue: Equatable, Sendable {
    public let instruments: [MarketInstrument]
    public let scope: String
    // Actions connues communes aux deux fournisseurs ; les indices restent conditionnels au catalogue réel.
    private static let starterStockSymbols = [
        "AAPL", "MSFT", "NVDA", "TSLA", "GOOGL", "AMZN", "META", "JPM", "V", "MA",
        "WMT", "COST", "NFLX", "AVGO", "AMD", "ORCL", "LLY", "XOM"
    ]
    private static let starterETFSymbols = ["SPY", "QQQ"]
    private static let starterIndices: [(symbols: Set<String>, names: [String], currency: String)] = [
        (["SPX", "GSPC"], ["S&P 500", "S&P500", "Standard & Poor’s 500"], "USD"),
        (["FCHI"], ["CAC 40", "CAC40"], "EUR")
    ]

    public var starters: [MarketInstrument] {
        guard let provider = instruments.first?.provider else { return [] }
        let stocks = Self.starterStockSymbols.compactMap { symbol in
            Self.preferred(symbol: symbol, currency: "USD", kinds: ["Stock", "Common Stock"], provider: provider, instruments: instruments)
        }
        let etfs = Self.starterETFSymbols.compactMap { symbol in
            Self.preferred(symbol: symbol, currency: "USD", kinds: ["ETF"], provider: provider, instruments: instruments)
        }
        guard provider == .twelveData else { return stocks + etfs }
        let indices = Self.starterIndices.compactMap { candidate in
            instruments.filter { item in
                item.provider == provider && item.currency == candidate.currency
                    && item.kind.caseInsensitiveCompare("Index") == .orderedSame
                    && (candidate.symbols.contains(item.symbol) || candidate.names.contains { item.name.localizedStandardContains($0) })
            }.sorted(by: Self.instrumentOrder).first
        }
        let indexIDs = Set(indices.map(\.id))
        let remainingETFs = max(0, Self.starterIndices.count - indices.count)
        return stocks + indices + Array(etfs.filter { !indexIDs.contains($0.id) }.prefix(remainingETFs))
    }

    private static func preferred(symbol: String, currency: String, kinds: [String], provider: MarketProvider,
                                  instruments: [MarketInstrument]) -> MarketInstrument? {
        instruments.filter { item in
            item.provider == provider && item.symbol == symbol && item.currency == currency
                && kinds.contains { item.kind.caseInsensitiveCompare($0) == .orderedSame }
        }.sorted(by: instrumentOrder).first
    }
    private static func instrumentOrder(_ left: MarketInstrument, _ right: MarketInstrument) -> Bool {
        let exchangeOrder = left.exchange.localizedStandardCompare(right.exchange)
        if exchangeOrder != .orderedSame { return exchangeOrder == .orderedAscending }
        return left.name.localizedStandardCompare(right.name) == .orderedAscending
    }
}
