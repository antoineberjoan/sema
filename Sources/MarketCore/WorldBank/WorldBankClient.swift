// Parle à l'API des indicateurs de la Banque mondiale : une adresse, un format JSON paginé, pas de clé.
import Foundation

public struct WorldBankClient: StatisticalConnector {
    private static let source = StatisticalSource.worldBank

    public init() { }

    public static func catalogueRequest(page: Int = 1) -> URLRequest {
        request(path: "/indicator?format=json&per_page=20000&page=\(page)")
    }

    public func datasets() async throws -> [StatisticalDataset] {
        var (metadata, rows) = try WorldBankMapping.response(try await download(Self.catalogueRequest()))
        var datasets = WorldBankMapping.datasets(rows)
        let pages = Int(metadata["pages"]?.text ?? "1") ?? 1
        if pages > 1 {
            for page in 2...pages {
                try Task.checkCancellation()
                (metadata, rows) = try WorldBankMapping.response(try await download(Self.catalogueRequest(page: page)))
                datasets += WorldBankMapping.datasets(rows)
            }
        }
        return datasets.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    public func structure(dataset: StatisticalDataset) async throws -> StatisticalStructure {
        let (_, rows) = try WorldBankMapping.response(try await download(Self.request(path: "/country?format=json&per_page=1000")))
        return .init(dimensions: [.init(id: "REF_AREA", title: "Pays ou agrégat", position: 1, codes: WorldBankMapping.countries(rows))], labels: [:])
    }

    public static func observationsRequest(dataset: StatisticalDataset, key: String, fullHistory: Bool = false, now: Date = .now) throws -> URLRequest {
        try PublicDataTransport.validateKey(key)
        let (start, calendar) = PublicDataTransport.historyStart(endingAt: now)
        let component = PublicDataTransport.component
        let period = fullHistory ? "" : "&date=\(calendar.component(.year, from: start)):\(calendar.component(.year, from: now))"
        return request(path: "/country/\(component(key))/indicator/\(component(dataset.code))?format=json&per_page=20000\(period)&source=\(component(dataset.agency))")
    }

    public func fetch(dataset: StatisticalDataset, structure: StatisticalStructure, key: String,
                      fullHistory: Bool, now: Date) async throws -> MarketSeries {
        let data = try await download(try Self.observationsRequest(dataset: dataset, key: key, fullHistory: fullHistory, now: now))
        return try WorldBankMapping.series(data, dataset: dataset, key: key, fullHistory: fullHistory, now: now)
    }

    private func download(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await PublicDataTransport.send(request)
        try PublicDataTransport.validate(response)
        return data
    }

    private static func request(path: String) -> URLRequest {
        PublicDataTransport.request(source.baseURL + path, accept: "application/json")
    }
}
