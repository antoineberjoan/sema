// Interroge Webstat avec une clé personnelle en en-tête et conserve la précision des observations.
import Foundation

/// Authenticated Banque de France observations. The user's key travels only in an HTTP header.
public struct WebstatClient: Sendable {
    static let timeout: TimeInterval = 30
    static let apiURL = "https://webstat.banque-france.fr/api/explore/v2.1/catalog/datasets/"
    /// Search results per page; the API refuses an offset beyond 10 000, so the last full page starts at 9 950.
    public static let pageSize = 50
    public static let maximumSearchOffset = 9_950
    /// From this offset on, the paged search is replaced by one lightweight export, paged locally.
    public static func usesSummaryExport(forOffset offset: Int) -> Bool { offset >= maximumSearchOffset }
    static let datasetPageSize = 100
    public init() {}

    public static func request(table: String, apiKey: String, parameters: [URLQueryItem]) throws -> URLRequest {
        guard ["series", "webstat-datasets", "codelists", "observations"].contains(table) else { throw WebstatError.invalidData }
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, key.rangeOfCharacter(from: .controlCharacters) == nil else { throw WebstatError.missingKey }
        var url = URLComponents(string: Self.apiURL + "\(table)/records")!
        url.queryItems = parameters
        var request = URLRequest(url: url.url!)
        request.setValue("Apikey \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = Self.timeout
        return request
    }

    /// Quotes are escaped inside ODSQL string literals; fields and tables are never supplied by users.
    public static func literal(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'") + "'"
    }

    public static func searchRequest(apiKey: String, search: WebstatSearch, offset: Int = 0) throws -> URLRequest {
        var filters: [String] = []
        let query = search.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            if WebstatSeriesDescriptor.isValidKey(query), query.contains(".") {
                filters.append("series_key = \(literal(query))")
            } else { filters.append("search(\(literal(String(query.prefix(300)))))") }
        }
        if !search.datasetID.isEmpty { filters.append("dataset_id = \(literal(search.datasetID))") }
        if !search.area.isEmpty {
            guard ["ref_area", "ame_ref_area", "zone_geo"].contains(search.areaField) else { throw WebstatError.invalidData }
            filters.append("\(search.areaField) = \(literal(search.area))")
        }
        if !search.frequency.isEmpty { filters.append("freq = \(literal(search.frequency))") }
        var parameters = [URLQueryItem(name: "limit", value: String(Self.pageSize)),
                          URLQueryItem(name: "offset", value: String(max(0, offset))),
                          URLQueryItem(name: "order_by", value: "series_key asc")]
        if !filters.isEmpty { parameters.append(URLQueryItem(name: "where", value: filters.joined(separator: " and "))) }
        return try request(table: "series", apiKey: apiKey, parameters: parameters)
    }

    public func search(apiKey: String, search: WebstatSearch, offset: Int = 0) async throws -> WebstatPage<WebstatSeriesDescriptor> {
        let data = try await send(Self.searchRequest(apiKey: apiKey, search: search, offset: offset))
        return try WebstatMapping.seriesPage(data, offset: offset)
    }

    /// ODSQL has no ordered text comparison. Offset paging stops before its 10,000-row cap;
    /// a user who reaches it can load this lightweight metadata index once and continue locally.
    public static func summaryExportRequest(apiKey: String, search: WebstatSearch) throws -> URLRequest {
        var request = try searchRequest(apiKey: apiKey, search: search)
        var url = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        url.path = url.path.replacingOccurrences(of: "/records", with: "/exports/json")
        url.queryItems = (url.queryItems ?? []).filter { !["limit", "offset"].contains($0.name) } + [
            .init(name: "select", value: "series_key,dataset_id,title_fr,freq,unit,unit_mult,ref_area")]
        request.url = url.url
        return request
    }
    public func exportSummaries(apiKey: String, search: WebstatSearch) async throws -> [WebstatSeriesDescriptor] {
        let data = try await send(Self.summaryExportRequest(apiKey: apiKey, search: search))
        try Task.checkCancellation()
        return try WebstatMapping.summaryExport(data)
    }
    public func datasets(apiKey: String) async throws -> [WebstatDataset] {
        var items: [WebstatDataset] = []; var offset = 0
        while true {
            let data = try await send(Self.request(table: "webstat-datasets", apiKey: apiKey,
                parameters: [.init(name: "limit", value: String(Self.datasetPageSize)), .init(name: "offset", value: String(offset)), .init(name: "order_by", value: "dataset_id")]))
            let page = try WebstatMapping.page(data)
            items += try page.results.map { try WebstatDataset(raw: $0) }
            offset += page.results.count
            if offset >= page.totalCount || page.results.isEmpty { break }
            try Task.checkCancellation()
        }
        return items
    }

    public func descriptor(apiKey: String, key: String) async throws -> WebstatSeriesDescriptor {
        guard WebstatSeriesDescriptor.isValidKey(key) else { throw WebstatError.invalidData }
        let page = try await search(apiKey: apiKey, search: WebstatSearch(query: key))
        guard let descriptor = page.items.first(where: { $0.key == key }) else { throw WebstatError.incompleteData }
        return descriptor
    }

    /// Exports are bounded by date. The caller requests older history in six-year slices.
    public func observations(apiKey: String, descriptor: WebstatSeriesDescriptor,
                             start: Date, end: Date = .now) async throws -> [MarketObservation] {
        let date = ISO8601DateFormatter(); date.formatOptions = [.withFullDate]
        let filter = "series_key = \(Self.literal(descriptor.key)) and time_period_start >= date'\(date.string(from: start))' and time_period_start <= date'\(date.string(from: end))'"
        var request = try Self.request(table: "observations", apiKey: apiKey, parameters: [
            .init(name: "select", value: "series_key,time_period_start,time_period_end,obs_value,obs_status,updated_at"),
            .init(name: "where", value: filter), .init(name: "order_by", value: "time_period_start,updated_at")])
        var url = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        url.path = url.path.replacingOccurrences(of: "/records", with: "/exports/json")
        request.url = url.url
        let data = try await send(request)
        let points = try WebstatMapping.observations(data, expectedKey: descriptor.key, now: end)
        return descriptor.series(observations: points).observations
    }

    public func codeLabels(apiKey: String, ids: [String]) async throws -> [String: [String: String]] {
        guard !ids.isEmpty else { return [:] }
        let filter = "codelist_id in (" + ids.map(Self.literal).joined(separator: ",") + ")"
        var request = try Self.request(table: "codelists", apiKey: apiKey, parameters: [
            .init(name: "where", value: filter), .init(name: "order_by", value: "codelist_id,code")])
        var url = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        url.path = url.path.replacingOccurrences(of: "/records", with: "/exports/json"); request.url = url.url
        let data = try await send(request)
        return WebstatMapping.codeLabels(try WebstatMapping.rows(data))
    }
    private func send(_ request: URLRequest) async throws -> Data {
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let data: Data; let response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch is CancellationError { throw CancellationError() }
        catch { if Task.isCancelled { throw CancellationError() }; throw WebstatError.unavailable }
        guard let http = response as? HTTPURLResponse else { throw WebstatError.unavailable }
        switch http.statusCode {
        case 200: return data
        case 401, 403, 404: throw WebstatError.accessDenied
        case 429: throw WebstatError.quotaReached
        default: throw WebstatError.unavailable
        }
    }


    /// Six years cover a full five-year window even when the latest monthly release lags behind today.
    public static func request(apiKey: String, now: Date = .now) throws -> URLRequest {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, key.rangeOfCharacter(from: .controlCharacters) == nil else {
            throw WebstatError.missingKey
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = HistoryPeriod.tranche(endingAt: now, calendar: calendar).start
        let date = ISO8601DateFormatter()
        date.formatOptions = [.withFullDate]
        var url = URLComponents(string: Self.apiURL + "observations/exports/json")!
        let keys = WebstatStarter.definitions.map { "'\($0.seriesCode)'" }.joined(separator: ",")
        url.queryItems = [
            URLQueryItem(name: "select", value: "series_key,time_period_start,time_period_end,obs_value,obs_status,updated_at"),
            URLQueryItem(name: "where", value: "series_key in (\(keys)) and time_period_start >= date'\(date.string(from: start))' and time_period_start <= date'\(date.string(from: now))'"),
            URLQueryItem(name: "order_by", value: "series_key,time_period_start")
        ]
        var request = URLRequest(url: url.url!)
        request.setValue("Apikey \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = Self.timeout
        return request
    }

    public func fetch(apiKey: String, now: Date = .now) async throws -> [MarketSeries] {
        let request = try Self.request(apiKey: apiKey, now: now)
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let data: Data
        let response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch is CancellationError { throw CancellationError() }
        catch { throw WebstatError.unavailable }
        guard let http = response as? HTTPURLResponse else { throw WebstatError.unavailable }
        return try WebstatMapping.starterHistory(data, statusCode: http.statusCode, now: now)
    }
}
