// Interroge Webstat avec une clé personnelle en en-tête et conserve la précision des observations.
import Foundation

/// Authenticated Banque de France observations. The user's key travels only in an HTTP header.
public struct WebstatClient: Sendable {
    static let timeout: TimeInterval = 30
    static let apiURL = "https://webstat.banque-france.fr/api/explore/v2.1/catalog/datasets/"
    public static let catalogueURL = "https://webstat.banque-france.fr/fr/catalogue/"
    public static let loginURL = URL(string: "https://webstat.banque-france.fr/login/")!
    /// Search results per page; the API refuses an offset beyond 10 000, so the last full page starts at 9 950.
    public static let pageSize = 50
    public static let maximumSearchOffset = 9_950
    static let datasetPageSize = 100
    public enum ClientError: Error, LocalizedError {
        case missingKey, accessDenied, quotaReached, unavailable, invalidData, incompleteData, metadataChanged

        public var errorDescription: String? {
            switch self {
            case .missingKey: "Ajoutez votre clé Webstat dans les réglages."
            case .accessDenied: "Accès Webstat refusé. Vérifiez votre clé et ses autorisations."
            case .quotaReached: "Le quota Webstat est atteint. Réessayez le lendemain."
            case .unavailable: "La connexion à Webstat a échoué. Réessayez plus tard."
            case .invalidData: "Le format des données Webstat n’a pas pu être lu."
            case .incompleteData: "Webstat n’a pas fourni les données attendues. Les observations précédentes sont conservées."
            case .metadataChanged: "L’unité, l’échelle ou la base de cette série a changé. Actualisez le repère avant de recharger son historique."
            }
        }
    }

    private struct Definition: Sendable {
        let id: String
        let key: String
        let name: String
        let subtitle: String
        let category: SeriesCategory
        let unit: ValueUnit
        let digits: Int
        let frequency: ObservationFrequency
        let producer: String
    }

    private static let definitions: [Definition] = [
        .init(id: "fr10", key: "FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD", name: "OAT France · 10 ans",
              subtitle: "Rendement · série mensuelle", category: .markets, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "ecb", key: "FM.D.U2.EUR.4F.KR.DFR.LEV", name: "Taux de dépôt BCE",
              subtitle: "Facilité de dépôt · politique monétaire", category: .savings, unit: .percent,
              digits: 2, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "eurusd", key: "EXR.D.USD.EUR.SP00.A", name: "Euro / Dollar",
              subtitle: "USD pour 1 EUR · taux de référence", category: .markets, unit: .usd,
              digits: 4, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "eurjpy", key: "EXR.D.JPY.EUR.SP00.A", name: "Euro / Yen",
              subtitle: "JPY pour 1 EUR · taux de référence", category: .markets, unit: .jpy,
              digits: 2, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "eurchf", key: "EXR.D.CHF.EUR.SP00.A", name: "Euro / Franc suisse",
              subtitle: "CHF pour 1 EUR · taux de référence", category: .markets, unit: .chf,
              digits: 4, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "livreta", key: "MIR1.M.FR.B.L23FRLA.D.R.A.2230U6.EUR.O", name: "Livret A",
              subtitle: "Épargne réglementée", category: .savings, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "lep", key: "MIR1.M.FR.B.L23FRLP.H.R.A.2250U6.EUR.O", name: "LEP",
              subtitle: "Épargne réglementée", category: .savings, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "inflation", key: "HICP.M.FR.N.000000.4D0.ANR", name: "Inflation · France",
              subtitle: "IPCH · variation annuelle · données brutes", category: .savings, unit: .percent,
              digits: 1, frequency: .monthly, producer: "Eurostat · via Banque de France"),
        .init(id: "ldds", key: "MIR1.M.FR.B.L23FRLD.D.R.A.2254U6.EUR.O", name: "LDDS",
              subtitle: "Épargne réglementée", category: .savings, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "estr", key: "ESTR.B.EU000A2X2A25.WT", name: "€STR",
              subtitle: "Marché monétaire au jour le jour", category: .savings, unit: .percent,
              digits: 3, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "inflation-euro", key: "HICP.M.U2.N.000000.4D0.ANR", name: "Inflation · Zone euro",
              subtitle: "IPCH · variation annuelle · données brutes", category: .savings, unit: .percent,
              digits: 1, frequency: .monthly, producer: "Eurostat · via Banque de France"),
        .init(id: "eurgbp", key: "EXR.D.GBP.EUR.SP00.A", name: "Euro / Livre sterling",
              subtitle: "GBP pour 1 EUR · taux de référence", category: .markets, unit: .gbp,
              digits: 4, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "mortgage-fr", key: "MIR1.M.FR.B.A22HR.A.R.A.2254U6.EUR.N", name: "Crédit immobilier",
              subtitle: "Nouveaux crédits à l’habitat · hors renégociations", category: .savings, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "de10", key: "FM.M.DE.EUR.FR2.BB.DE10YT_RR.YLD", name: "Bund · 10 ans",
              subtitle: "Rendement · série mensuelle", category: .markets, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "us10", key: "FM.M.US.USD.FR2.BB.US10YT_RR.YLD", name: "Treasury US · 10 ans",
              subtitle: "Rendement · série mensuelle", category: .markets, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "mro", key: "FM.D.U2.EUR.4F.KR.MRR_FR.LEV", name: "Taux de refinancement BCE",
              subtitle: "Opérations principales · politique monétaire", category: .savings, unit: .percent,
              digits: 2, frequency: .daily, producer: "BCE · via Banque de France")
    ]

    public init() {}

    public static var legacyIDs: [String: String] {
        Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0.key) })
    }
    public static func canonicalID(_ id: String) -> String { legacyIDs[id] ?? id }
    public static var starterIDs: [String] { definitions.map(\.key) }
    public static var starterSeries: [MarketSeries] {
        let demos = DemoCatalog.series()
        return definitions.map { definition in
            let sample = demos.first { $0.id == definition.id }
            return MarketSeries(id: definition.key, name: definition.name, subtitle: definition.subtitle,
                category: definition.category, unit: definition.unit, fractionDigits: definition.digits,
                source: definition.producer, isDemo: true, frequency: definition.frequency,
                observations: sample?.observations ?? [])
        }
    }

    public static func request(table: String, apiKey: String, parameters: [URLQueryItem]) throws -> URLRequest {
        guard ["series", "webstat-datasets", "codelists", "observations"].contains(table) else { throw ClientError.invalidData }
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, key.rangeOfCharacter(from: .controlCharacters) == nil else { throw ClientError.missingKey }
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
            guard ["ref_area", "ame_ref_area", "zone_geo"].contains(search.areaField) else { throw ClientError.invalidData }
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
        return try Self.parseSeriesPage(data, offset: offset)
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
        return try Self.parseSummaryExport(data)
    }
    public static func parseSummaryExport(_ data: Data) throws -> [WebstatSeriesDescriptor] {
        let rows: [[String: WebstatValue]]
        do { rows = try JSONDecoder().decode([[String: WebstatValue]].self, from: data) } catch { throw ClientError.invalidData }
        let items = try rows.map { try WebstatSeriesDescriptor(raw: $0) }
        guard Set(items.map(\.key)).count == items.count else { throw ClientError.invalidData }
        // Keep the provider’s text collation: exports and records use the same order_by.
        return items
    }

    public static func parseSeriesPage(_ data: Data, offset: Int = 0) throws -> WebstatPage<WebstatSeriesDescriptor> {
        let page = try decodePage(data)
        return WebstatPage(items: try page.results.map { try WebstatSeriesDescriptor(raw: $0) }, total: page.totalCount, offset: offset)
    }

    public func datasets(apiKey: String) async throws -> [WebstatDataset] {
        var items: [WebstatDataset] = []; var offset = 0
        while true {
            let data = try await send(Self.request(table: "webstat-datasets", apiKey: apiKey,
                parameters: [.init(name: "limit", value: String(Self.datasetPageSize)), .init(name: "offset", value: String(offset)), .init(name: "order_by", value: "dataset_id")]))
            let page = try Self.decodePage(data)
            items += try page.results.map { try WebstatDataset(raw: $0) }
            offset += page.results.count
            if offset >= page.totalCount || page.results.isEmpty { break }
            try Task.checkCancellation()
        }
        return items
    }

    public func descriptor(apiKey: String, key: String) async throws -> WebstatSeriesDescriptor {
        guard WebstatSeriesDescriptor.isValidKey(key) else { throw ClientError.invalidData }
        let page = try await search(apiKey: apiKey, search: WebstatSearch(query: key))
        guard let descriptor = page.items.first(where: { $0.key == key }) else { throw ClientError.incompleteData }
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
        let points = try Self.parseObservations(data, expectedKey: descriptor.key, now: end)
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
        let rows: [[String: WebstatValue]]
        do { rows = try JSONDecoder().decode([[String: WebstatValue]].self, from: data) } catch { throw ClientError.invalidData }
        return Self.parseCodeLabels(rows)
    }
    public static func parseCodeLabels(_ rows: [[String: WebstatValue]]) -> [String: [String: String]] {
        var labels: [String: [String: String]] = [:]
        for row in rows {
            if let list = row["codelist_id"]?.text, let code = row["code"]?.text,
               let label = row["label_fr"]?.text ?? row["label_en"]?.text { labels[list, default: [:]][code] = label }
        }
        return labels
    }

    public static func parseObservations(_ data: Data, expectedKey: String, now: Date = .now) throws -> [MarketObservation] {
        let rows: [Row]
        do { rows = try JSONDecoder().decode([Row].self, from: data) } catch { throw ClientError.invalidData }
        let timestamp = ISO8601DateFormatter(); timestamp.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        return rows.sorted { ($0.updatedAt ?? "") < ($1.updatedAt ?? "") }.compactMap { row in
            guard row.key == expectedKey, let value = row.value, !value.isNaN,
                  let date = WebstatSeriesDescriptor.date(row.start), date <= now,
                  let end = WebstatSeriesDescriptor.date(row.end), end >= date,
                  row.status != "M", row.status != "Q" else { return nil }
            return MarketObservation(date: date, value: value, periodEnd: end,
                updatedAt: row.updatedAt.flatMap { timestamp.date(from: $0) ?? fallback.date(from: $0) }, status: row.status)
        }
    }

    private struct Page: Decodable {
        let totalCount: Int
        let results: [[String: WebstatValue]]
        enum CodingKeys: String, CodingKey { case totalCount = "total_count", results }
    }
    private static func decodePage(_ data: Data) throws -> Page {
        do { return try JSONDecoder().decode(Page.self, from: data) } catch { throw ClientError.invalidData }
    }
    private func send(_ request: URLRequest) async throws -> Data {
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let data: Data; let response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch is CancellationError { throw CancellationError() }
        catch { if Task.isCancelled { throw CancellationError() }; throw ClientError.unavailable }
        guard let http = response as? HTTPURLResponse else { throw ClientError.unavailable }
        switch http.statusCode {
        case 200: return data
        case 401, 403, 404: throw ClientError.accessDenied
        case 429: throw ClientError.quotaReached
        default: throw ClientError.unavailable
        }
    }


    /// Six years cover a full five-year window even when the latest monthly release lags behind today.
    public static func request(apiKey: String, now: Date = .now) throws -> URLRequest {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, key.rangeOfCharacter(from: .controlCharacters) == nil else {
            throw ClientError.missingKey
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(byAdding: .year, value: -HistoryPeriod.recentYears, to: now)!
        let date = ISO8601DateFormatter()
        date.formatOptions = [.withFullDate]
        var url = URLComponents(string: Self.apiURL + "observations/exports/json")!
        let keys = definitions.map { "'\($0.key)'" }.joined(separator: ",")
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
        catch { throw ClientError.unavailable }
        guard let http = response as? HTTPURLResponse else { throw ClientError.unavailable }
        return try Self.parse(data, statusCode: http.statusCode, now: now)
    }

    public static func parse(_ data: Data, statusCode: Int = 200, now: Date = .now) throws -> [MarketSeries] {
        switch statusCode {
        case 200: break
        // Webstat also returns 404 when the API key cannot access a technical table.
        case 401, 403, 404: throw ClientError.accessDenied
        case 429: throw ClientError.quotaReached
        default: throw ClientError.unavailable
        }
        let rows: [Row]
        do { rows = try JSONDecoder().decode([Row].self, from: data) }
        catch { throw ClientError.invalidData }
        let day = ISO8601DateFormatter()
        day.formatOptions = [.withFullDate]
        let timestamp = ISO8601DateFormatter()
        timestamp.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestampWithoutFraction = ISO8601DateFormatter()
        var grouped: [String: [MarketObservation]] = [:]
        // Latest revision wins, independently of export ordering for duplicate dates.
        for row in rows.sorted(by: { ($0.updatedAt ?? "") < ($1.updatedAt ?? "") }) {
            guard let value = row.value, !value.isNaN,
                  let date = day.date(from: row.start), date <= now,
                  let end = day.date(from: row.end), end >= date,
                  row.status != "M", row.status != "Q" else { continue }
            let updated = row.updatedAt.flatMap { timestamp.date(from: $0) ?? timestampWithoutFraction.date(from: $0) }
            grouped[row.key, default: []].append(.init(date: date, value: value,
                periodEnd: end, updatedAt: updated, status: row.status))
        }
        return try definitions.map { definition in
            let observations = (grouped[definition.key] ?? []).filter {
                definition.unit == .percent || $0.value > 0
            }
            guard !observations.isEmpty else { throw ClientError.incompleteData }
            return MarketSeries(id: definition.id, name: definition.name, subtitle: definition.subtitle,
                category: definition.category, unit: definition.unit, fractionDigits: definition.digits,
                source: definition.producer,
                sourceURL: URL(string: Self.catalogueURL + "\(definition.key.split(separator: ".")[0].lowercased())/\(definition.key)"),
                isDemo: false, frequency: definition.frequency, observations: observations)
        }
    }

    private struct Row: Decodable {
        let key: String
        let start: String
        let end: String
        let value: Decimal?
        let status: String?
        let updatedAt: String?

        enum CodingKeys: String, CodingKey {
            case key = "series_key", start = "time_period_start", end = "time_period_end"
            case value = "obs_value", status = "obs_status", updatedAt = "updated_at"
        }
    }
}
