// Parle aux taux de référence de la Fed de New York : une adresse, un format JSON, pas de clé.
import Foundation

public struct NewYorkFedClient: StatisticalConnector {
    static let measurePrefix = "MEASURE:"
    private static let source = StatisticalSource.newYorkFed

    public init() { }

    public static func catalogueRequest() -> URLRequest { request(path: "/all/latest.json") }

    public func datasets() async throws -> [StatisticalDataset] {
        let (data, response) = try await PublicDataTransport.send(Self.catalogueRequest())
        try PublicDataTransport.validate(response)
        return try NewYorkFedMapping.datasets(data)
    }

    /// Les mesures d'un taux sont déjà dans le catalogue : aucun appel de plus.
    public func structure(dataset: StatisticalDataset) async throws -> StatisticalStructure {
        let fields = dataset.metadata.keys.filter { $0.hasPrefix(Self.measurePrefix) }.sorted()
        return .init(dimensions: [.init(id: "MEASURE", title: "Mesure", position: 1,
            codes: fields.map { .init(id: String($0.dropFirst(Self.measurePrefix.count)), title: dataset.metadata[$0]!) })], labels: [:])
    }

    public static func observationsRequest(dataset: StatisticalDataset, key: String, fullHistory: Bool = false, now: Date = .now) throws -> URLRequest {
        try PublicDataTransport.validateKey(key)
        let start = PublicDataTransport.historyStart(endingAt: now).start
        let day = PublicDataTransport.day
        let route = dataset.metadata["ROUTE"] ?? "all"
        return request(path: "/\(route)/search.json?startDate=\(fullHistory ? PublicDataTransport.fullHistoryStart : day(start))&endDate=\(day(now))")
    }

    public func fetch(dataset: StatisticalDataset, structure: StatisticalStructure, key: String,
                      fullHistory: Bool, now: Date) async throws -> MarketSeries {
        let (data, response) = try await PublicDataTransport.send(try Self.observationsRequest(dataset: dataset, key: key, fullHistory: fullHistory, now: now))
        try PublicDataTransport.validate(response)
        return try NewYorkFedMapping.series(data, dataset: dataset, key: key, fullHistory: fullHistory, now: now)
    }

    private static func request(path: String) -> URLRequest {
        PublicDataTransport.request(source.baseURL + path, accept: "application/json")
    }
}
