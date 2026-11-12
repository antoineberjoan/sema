// Choisit le connecteur statistique d'une source et le lui fait parler ; ne contient aucune règle de décodage.
import Foundation
import MarketCore

struct StatisticalConnectors: Sendable {
    /// Clé FRED personnelle, lue dans le Trousseau ; elle part seulement vers FRED.
    let fredKey: String?

    func connector(for source: StatisticalSource) -> any StatisticalConnector {
        switch source {
        case .newYorkFed: NewYorkFedClient()
        case .worldBank: WorldBankClient()
        case .fred: FredClient(key: fredKey)
        case .insee, .ecb, .eurostat, .bis, .oecd: SdmxClient(source: source)
        }
    }

    func datasets(source: StatisticalSource) async throws -> [StatisticalDataset] {
        try await connector(for: source).datasets()
    }

    func structure(dataset: StatisticalDataset) async throws -> StatisticalStructure {
        try await connector(for: dataset.source).structure(dataset: dataset)
    }

    func seriesCatalogue(dataset: StatisticalDataset, structure: StatisticalStructure) async throws -> [StatisticalSeriesDescriptor] {
        try await connector(for: dataset.source).seriesCatalogue(dataset: dataset, structure: structure)
    }

    func fetch(dataset: StatisticalDataset, structure: StatisticalStructure, key: String) async throws -> MarketSeries {
        try await connector(for: dataset.source).fetch(dataset: dataset, structure: structure, key: key)
    }

    func observations(for descriptor: StatisticalSeriesDescriptor) async throws -> MarketSeries {
        try await connector(for: descriptor.dataset.source).observations(for: descriptor)
    }

    func fetch(_ descriptor: StatisticalSeriesDescriptor, fullHistory: Bool = false) async throws -> MarketSeries {
        try await connector(for: descriptor.dataset.source).fetch(descriptor, fullHistory: fullHistory)
    }

    func releaseDates(on day: Date) async throws -> [EconomicRelease] {
        try await FredClient(key: fredKey).releaseDates(on: day)
    }
}
