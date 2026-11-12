// Ce que l'app demande à un fournisseur de cours à clé personnelle.
import Foundation

public protocol MarketDataConnector: Sendable {
    func validate(key: String) async throws
    func invalidateCatalogue() async
    func catalogue(key: String) async throws -> MarketCatalogue
    func fetch(_ instrument: MarketInstrument, key: String) async throws -> MarketSeries
}
