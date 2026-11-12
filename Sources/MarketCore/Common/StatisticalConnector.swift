// Ce que l'app demande à un connecteur statistique, quel que soit le service derrière.
import Foundation

public protocol StatisticalConnector: Sendable {
    func datasets() async throws -> [StatisticalDataset]
    func structure(dataset: StatisticalDataset) async throws -> StatisticalStructure
    func seriesCatalogue(dataset: StatisticalDataset, structure: StatisticalStructure) async throws -> [StatisticalSeriesDescriptor]
    func fetch(dataset: StatisticalDataset, structure: StatisticalStructure, key: String,
               fullHistory: Bool, now: Date) async throws -> MarketSeries
    /// Charge les observations courantes d'une série choisie, quelle que soit sa mesure ; l'appelant les compare lui-même.
    func observations(for descriptor: StatisticalSeriesDescriptor, fullHistory: Bool, now: Date) async throws -> MarketSeries
}

extension StatisticalConnector {
    /// Un service sans catalogue de séries propose une série par code de sa seule dimension.
    public func seriesCatalogue(dataset: StatisticalDataset, structure: StatisticalStructure) async throws -> [StatisticalSeriesDescriptor] {
        guard let dimension = structure.dimensions.first else { throw PublicDataError.invalidData }
        return dimension.codes.map { code in
            .init(dataset: dataset, key: code.id, dimensionIDs: [dimension.id],
                fields: ["TITLE": dataset.title + " · " + code.title, dimension.id: code.id],
                labels: [dimension.id: code.title])
        }
    }

    public func observations(for descriptor: StatisticalSeriesDescriptor, fullHistory: Bool, now: Date) async throws -> MarketSeries {
        let structure = try await structure(dataset: descriptor.dataset)
        return try await fetch(dataset: descriptor.dataset, structure: structure, key: descriptor.key, fullHistory: fullHistory, now: now)
    }

    public func observations(for descriptor: StatisticalSeriesDescriptor) async throws -> MarketSeries {
        try await observations(for: descriptor, fullHistory: false, now: .now)
    }

    /// Charge une série suivie et refuse la réponse si sa mesure a changé.
    public func fetch(_ descriptor: StatisticalSeriesDescriptor, fullHistory: Bool = false, now: Date = .now) async throws -> MarketSeries {
        let value = try await observations(for: descriptor, fullHistory: fullHistory, now: now)
        guard let next = value.statisticalDescriptor, descriptor.usesSameMeasurement(as: next) else { throw PublicDataError.metadataChanged }
        return value
    }

    public func fetch(dataset: StatisticalDataset, structure: StatisticalStructure, key: String) async throws -> MarketSeries {
        try await fetch(dataset: dataset, structure: structure, key: key, fullHistory: false, now: .now)
    }
}
