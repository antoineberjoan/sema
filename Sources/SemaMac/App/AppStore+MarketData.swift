// Relie les connexions personnelles et les instruments aux repères et à leur actualisation partagée.
import Foundation
import MarketCore

extension AppStore {
    func checkMarketKeys() async {
        guard !didCheckMarketKeys else { return }
        didCheckMarketKeys = true
        for provider in MarketProvider.allCases {
            do { if try await marketKeychains[provider]?.read() != nil { connectedMarkets.insert(provider) } }
            catch { marketErrors[provider] = "Le Trousseau n’a pas pu lire cette clé." }
        }
    }

    func connectMarket(_ provider: MarketProvider, key: String) async -> Bool {
        guard !connectingMarkets.contains(provider), isSourceEnabled(provider.rawValue),
              let client = marketClients[provider], let keychain = marketKeychains[provider] else { return false }
        connectingMarkets.insert(provider); marketErrors[provider] = nil
        defer { connectingMarkets.remove(provider) }
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let generation = sourceGenerations[provider.rawValue]
        do {
            try await client.validate(key: key)
            guard isSourceEnabled(provider.rawValue), generation == sourceGenerations[provider.rawValue] else { return false }
            try await keychain.save(key)
            await client.invalidateCatalogue()
            connectedMarkets.insert(provider)
            sourceGenerations[provider.rawValue] = UUID()
            return true
        } catch { marketErrors[provider] = error.localizedDescription; return false }
    }

    func removeMarketKey(_ provider: MarketProvider) async {
        guard !connectingMarkets.contains(provider), !isLoading else { return }
        do {
            try await marketKeychains[provider]?.remove()
            await marketClients[provider]?.invalidateCatalogue()
            connectedMarkets.remove(provider); marketErrors[provider] = nil
            sourceGenerations[provider.rawValue] = UUID()
        } catch { marketErrors[provider] = "Le Trousseau n’a pas pu retirer cette clé." }
    }

    func marketCatalogue(_ provider: MarketProvider) async throws -> MarketCatalogue {
        guard isSourceEnabled(provider.rawValue) else { throw CancellationError() }
        guard let key = try await marketKeychains[provider]?.read(), let client = marketClients[provider] else { throw MarketDataError.missingKey }
        let generation = sourceGenerations[provider.rawValue]
        let catalogue = try await client.catalogue(key: key)
        try Task.checkCancellation()
        guard isSourceEnabled(provider.rawValue), connectedMarkets.contains(provider),
              generation == sourceGenerations[provider.rawValue] else { throw CancellationError() }
        return catalogue
    }

    func fetchMarket(_ instrument: MarketInstrument) async throws -> MarketSeries {
        let provider = instrument.provider
        guard isSourceEnabled(provider.rawValue), connectedMarkets.contains(provider) else { throw MarketDataError.missingKey }
        guard let key = try await marketKeychains[provider]?.read(), let client = marketClients[provider] else { throw MarketDataError.missingKey }
        let generation = sourceGenerations[provider.rawValue]
        let value = try await client.fetch(instrument, key: key)
        try Task.checkCancellation()
        guard isSourceEnabled(provider.rawValue), connectedMarkets.contains(provider),
              generation == sourceGenerations[provider.rawValue] else { throw CancellationError() }
        return value
    }
}
