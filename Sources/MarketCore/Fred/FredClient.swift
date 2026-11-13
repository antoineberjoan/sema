// Parle à FRED, la base de la Fed de Saint-Louis : une adresse, un format JSON, une clé personnelle reçue en paramètre.
import Foundation

public struct FredClient: StatisticalConnector {
    /// FRED renvoie au plus 1 000 séries par page ; une publication est listée par popularité, les plus utilisées d’abord.
    static let pageLimit = 1000
    private static let source = StatisticalSource.fred
    /// Clé personnelle, ajoutée aux requêtes seulement à l’envoi, pour que ni les constructeurs de requêtes ni les journaux ne la détiennent.
    private let key: String?

    public init(key: String? = nil) { self.key = key }

    public static func catalogueRequest() -> URLRequest { request(path: "/releases?file_type=json&limit=\(pageLimit)") }

    public func datasets() async throws -> [StatisticalDataset] {
        try FredMapping.datasets(try await download(Self.catalogueRequest()))
    }

    public func structure(dataset: StatisticalDataset) async throws -> StatisticalStructure {
        let data = try await download(Self.releaseSeriesRequest(dataset))
        return .init(dimensions: [.init(id: "SERIES", title: "Série", position: 1, codes: try FredMapping.seriesCodes(data))], labels: [:])
    }

    public static func observationsRequest(dataset: StatisticalDataset, key: String, fullHistory: Bool = false, now: Date = .now) throws -> URLRequest {
        try PublicDataTransport.validateKey(key)
        let start = PublicDataTransport.historyStart(endingAt: now).start
        return request(path: "/series/observations?series_id=\(PublicDataTransport.component(key))&file_type=json" + (fullHistory ? "" : "&observation_start=\(PublicDataTransport.day(start))"))
    }

    public func fetch(dataset: StatisticalDataset, structure: StatisticalStructure, key: String,
                      fullHistory: Bool, now: Date) async throws -> MarketSeries {
        let data = try await download(try Self.observationsRequest(dataset: dataset, key: key, fullHistory: fullHistory, now: now))
        let metadata = try await download(Self.seriesRequest(key: key))
        return try FredMapping.series(observations: data, metadata: metadata, dataset: dataset, key: key, fullHistory: fullHistory, now: now)
    }

    /// Une série se nomme par son propre identifiant : sa liste de publications n’est pas nécessaire pour l’actualiser.
    public func observations(for descriptor: StatisticalSeriesDescriptor, fullHistory: Bool, now: Date) async throws -> MarketSeries {
        try await fetch(dataset: descriptor.dataset, structure: .init(dimensions: [], labels: [:]), key: descriptor.key, fullHistory: fullHistory, now: now)
    }

    static func releaseDatesRequest(on day: Date) -> URLRequest {
        let text = PublicDataTransport.day(day)
        return request(path: "/releases/dates?realtime_start=\(text)&realtime_end=\(text)&include_release_dates_with_no_data=true&file_type=json&limit=\(pageLimit)")
    }

    /// Publications économiques prévues un jour donné, d’après le calendrier FRED.
    public func releaseDates(on day: Date) async throws -> [EconomicRelease] {
        try FredMapping.releaseDates(try await download(Self.releaseDatesRequest(on: day)))
    }

    /// Vérifie une clé par une petite requête avant son enregistrement.
    public func validateKey() async throws {
        _ = try await download(Self.seriesRequest(key: "DGS10"))
    }

    static func releaseSeriesRequest(_ dataset: StatisticalDataset) -> URLRequest {
        request(path: "/release/series?release_id=\(PublicDataTransport.component(dataset.code))&file_type=json&limit=\(pageLimit)&order_by=popularity&sort_order=desc")
    }

    static func seriesRequest(key: String) -> URLRequest {
        request(path: "/series?series_id=\(PublicDataTransport.component(key))&file_type=json")
    }

    private func download(_ request: URLRequest) async throws -> Data {
        var request = request
        // FRED documente seulement le paramètre de requête `api_key` ; l’URL n’est jamais journalisée ni mise en cache.
        guard let key, !key.isEmpty, let url = request.url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw PublicDataError.missingAPIKey }
        components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "api_key", value: key)]
        request.url = components.url
        let (data, response) = try await PublicDataTransport.send(request)
        if (response as? HTTPURLResponse)?.statusCode == 400 { throw PublicDataError.rejectedAPIKey }
        try PublicDataTransport.validate(response)
        return data
    }

    private static func request(path: String) -> URLRequest {
        PublicDataTransport.request(source.baseURL + path, accept: "application/json")
    }
}
