// Parle à FRED, la base de la Fed de Saint-Louis : une adresse, un format JSON, une clé personnelle reçue en paramètre.
import Foundation

public struct FredClient: StatisticalConnector {
    /// FRED returns at most 1 000 series per page; a release is listed by popularity, most used first.
    static let pageLimit = 1000
    private static let source = StatisticalSource.fred
    /// Personal key, added to requests only at sending time so request builders and logs never hold it.
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

    /// A series is named by its own identifier: its release list is not needed to refresh it.
    public func observations(for descriptor: StatisticalSeriesDescriptor, fullHistory: Bool, now: Date) async throws -> MarketSeries {
        try await fetch(dataset: descriptor.dataset, structure: .init(dimensions: [], labels: [:]), key: descriptor.key, fullHistory: fullHistory, now: now)
    }

    static func releaseDatesRequest(on day: Date) -> URLRequest {
        let text = PublicDataTransport.day(day)
        return request(path: "/releases/dates?realtime_start=\(text)&realtime_end=\(text)&include_release_dates_with_no_data=true&file_type=json&limit=\(pageLimit)")
    }

    /// Economic publications scheduled on a day, from the FRED calendar.
    public func releaseDates(on day: Date) async throws -> [EconomicRelease] {
        try FredMapping.releaseDates(try await download(Self.releaseDatesRequest(on: day)))
    }

    /// Checks a key with one small request before it is saved.
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
        // FRED documents only the `api_key` query parameter; the URL is never logged nor cached.
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
