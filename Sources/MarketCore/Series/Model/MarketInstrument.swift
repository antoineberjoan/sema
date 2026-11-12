// Identifie un instrument et sa fréquence sans confondre indice, ETF et action.
import Foundation

public struct MarketInstrument: Codable, Equatable, Identifiable, Sendable {
    public let provider: MarketProvider
    public let symbol: String
    public let name: String
    public let exchange: String
    public let currency: String
    public let kind: String
    public let isWeekly: Bool
    enum CodingKeys: String, CodingKey {
        case provider, symbol, name, exchange, currency, kind
        case isWeekly = "weekly"
    }
    public var id: String {
        [provider.rawValue, symbol, exchange, isWeekly ? "weekly" : "daily"]
            .map { $0.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? $0 }.joined(separator: ":")
    }
    public init(provider: MarketProvider, symbol: String, name: String, exchange: String,
                currency: String, kind: String, isWeekly: Bool = false) {
        self.provider = provider; self.symbol = symbol; self.name = name
        self.exchange = exchange; self.currency = currency; self.kind = kind; self.isWeekly = isWeekly
    }
    public func usingWeekly(_ value: Bool) -> MarketInstrument {
        MarketInstrument(provider: provider, symbol: symbol, name: name, exchange: exchange,
                         currency: currency, kind: kind, isWeekly: value)
    }
    public var summary: String { [symbol, exchange, kindLabel, isWeekly ? "Hebdomadaire" : "Quotidien"].filter { !$0.isEmpty }.joined(separator: " · ") }
    private var kindLabel: String {
        switch kind.lowercased() {
        case "common stock", "stock", "equity": "Action"
        case "preferred stock": "Action privilégiée"
        case "index": "Indice"
        default: kind
        }
    }
    public var displayUnit: String { kind.lowercased().contains("index") ? "points" : currency }
}
