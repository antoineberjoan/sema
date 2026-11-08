// Découvre les catalogues publics et charge une série choisie avec son contrat de source.
import Foundation

/// Catalogue discovery is independent of observations: no bulk download of every time series.
public struct StatisticalClient: Sendable {
    static let timeout: TimeInterval = 45
    static let maximumKeyLength = 1000
    static let fullHistoryStart = "2000-01-01"
    static let measurePrefix = "MEASURE:"
    public enum ClientError: Error, LocalizedError {
        case unavailable, quotaReached, invalidData, noData, metadataChanged, chooseOneSeries, invalidKey, unsupportedPeriod, catalogueTooLarge, missingAPIKey, rejectedAPIKey
        public var errorDescription: String? {
            switch self {
            case .unavailable: "La source est indisponible. Les observations précédentes restent conservées."
            case .quotaReached: "La source limite les requêtes. Réessayez plus tard."
            case .invalidData: "Le format de cette réponse n’a pas pu être interprété."
            case .noData: "Aucune observation numérique pour cette combinaison et cette période."
            case .metadataChanged: "L’unité, l’échelle ou la base a changé. Les anciennes observations restent conservées ; vérifiez la définition avant de suivre la nouvelle série."
            case .chooseOneSeries: "Cette combinaison renvoie plusieurs séries. Précisez chaque dimension pour choisir un repère unique."
            case .invalidKey: "Choisissez une valeur pour chaque dimension, ou renseignez une clé exacte valide."
            case .unsupportedPeriod: "La source utilise une période que Sema ne sait pas encore lire. L’historique n’est pas présenté comme complet."
            case .catalogueTooLarge: "Ce catalogue est trop volumineux. Précisez le repère dans Recherche avancée."
            case .missingAPIKey: "Connectez votre clé FRED gratuite dans Réglages → Sources."
            case .rejectedAPIKey: "FRED refuse cette clé. Vérifiez-la dans Réglages → Sources ; les observations précédentes restent conservées."
            }
        }
    }
    /// Personal FRED key, added to FRED requests only at sending time so request builders and logs never hold it.
    private let fredKey: String?
    public init(fredKey: String? = nil) { self.fredKey = fredKey }
    /// FRED returns at most 1 000 series per page; a release is listed by popularity, most used first.
    static let fredPageLimit = 1000

    // Bound the XML tree and the list held in memory; never present a truncated catalogue.
    private static let seriesCatalogueByteLimit = 20 * 1024 * 1024

    public static func catalogueRequest(_ source: StatisticalSource) -> URLRequest {
        let path: String
        switch source {
        case .insee: path = "/dataflow"
        case .ecb: path = "/dataflow/ECB/all/latest?references=none"
        case .eurostat: path = "/dataflow/ESTAT/all/latest?references=none"
        case .bis: path = "/structure/dataflow/BIS/all/latest?references=none"
        case .oecd: path = "/dataflow/all/all/latest?references=none"
        case .newYorkFed: path = "/all/latest.json"
        case .worldBank: path = "/indicator?format=json&per_page=20000&page=1"
        case .fred: path = "/releases?file_type=json&limit=\(fredPageLimit)"
        }
        return request(source: source, path: path, structure: true)
    }
    public func datasets(source: StatisticalSource) async throws -> [StatisticalDataset] {
        let data = try await download(Self.catalogueRequest(source))
        if source.isSDMX { return try SDMXParser.datasets(data, source: source) }
        if source == .newYorkFed { return try Self.fedDatasets(data) }
        if source == .fred { return try Self.fredDatasets(data) }
        var (metadata, rows) = try Self.bankResponse(data)
        var datasets = Self.bankDatasets(rows)
        let pages = Int(metadata["pages"]?.text ?? "1") ?? 1
        if pages > 1 {
            for page in 2...pages {
                try Task.checkCancellation()
                let response = try await download(Self.request(source: source, path: "/indicator?format=json&per_page=20000&page=\(page)", structure: true))
                (metadata, rows) = try Self.bankResponse(response)
                datasets += Self.bankDatasets(rows)
            }
        }
        return datasets.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    public func structure(dataset: StatisticalDataset) async throws -> StatisticalStructure {
        if dataset.source == .newYorkFed {
            let fields = dataset.metadata.keys.filter { $0.hasPrefix(Self.measurePrefix) }.sorted()
            return .init(dimensions: [.init(id: "MEASURE", title: "Mesure", position: 1,
                codes: fields.map { .init(id: String($0.dropFirst(Self.measurePrefix.count)), title: dataset.metadata[$0]!) })], labels: [:])
        }
        if dataset.source == .fred {
            let data = try await download(Self.fredReleaseSeriesRequest(dataset))
            return .init(dimensions: [.init(id: "SERIES", title: "Série", position: 1, codes: try Self.fredSeriesCodes(data))], labels: [:])
        }
        if dataset.source == .worldBank {
            let data = try await download(Self.request(source: .worldBank, path: "/country?format=json&per_page=1000", structure: true))
            let (_, rows) = try Self.bankResponse(data)
            let countries = rows.compactMap { row -> StatisticalCode? in
                guard let id = row["id"]?.text, let name = row["name"]?.text else { return nil }
                return .init(id: id, title: name)
            }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            return .init(dimensions: [.init(id: "REF_AREA", title: "Pays ou agrégat", position: 1, codes: countries)], labels: [:])
        }
        let data = try await download(Self.structureRequest(dataset))
        let structure = try SDMXParser.structure(data, dataset: dataset)
        var additional: [Data] = []
        for reference in structure.missingCodelists {
            try Task.checkCancellation()
            let prefix = dataset.source == .bis ? "/structure" : ""
            let path = "\(prefix)/codelist/\(Self.component(reference.agency))/\(Self.component(reference.code))/\(Self.component(reference.version))"
            do { additional.append(try await download(Self.request(source: dataset.source, path: path, structure: true))) }
            catch is CancellationError { throw CancellationError() }
            catch ClientError.quotaReached { throw ClientError.quotaReached }
            catch { } // An unavailable codelist leaves an explicit code field; observations remain accessible.
        }
        return additional.isEmpty ? structure : try SDMXParser.structure(data, dataset: dataset, additionalCodelists: additional)
    }
    public static func structureRequest(_ dataset: StatisticalDataset) -> URLRequest {
        let source = dataset.source
        let prefix = source == .bis ? "/structure" : ""
        let references = source == .eurostat ? "descendants" : "all"
        let detail = source == .eurostat ? "&detail=referencepartial" : ""
        return request(source: source, path: "\(prefix)/dataflow/\(component(dataset.agency))/\(component(dataset.code))/\(component(dataset.version))?references=\(references)\(detail)", structure: true)
    }

    public static func seriesCatalogueRequest(_ dataset: StatisticalDataset) -> URLRequest {
        var value = request(source: dataset.source, path: dataPath(dataset, key: "") + "?detail=nodata")
        value.setValue("application/vnd.sdmx.structurespecificdata+xml;version=2.1", forHTTPHeaderField: "Accept")
        return value
    }

    public func seriesCatalogue(dataset: StatisticalDataset, structure: StatisticalStructure) async throws -> [StatisticalSeriesDescriptor] {
        if !dataset.source.isSDMX {
            guard let dimension = structure.dimensions.first else { throw ClientError.invalidData }
            return dimension.codes.map { code in
                .init(dataset: dataset, key: code.id, dimensionIDs: [dimension.id],
                    fields: ["TITLE": dataset.title + " · " + code.title, dimension.id: code.id],
                    labels: [dimension.id: code.title])
            }
        }
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(for: Self.seriesCatalogueRequest(dataset))
        try Self.validate(response)
        guard response.expectedContentLength <= Int64(Self.seriesCatalogueByteLimit) else { throw ClientError.catalogueTooLarge }
        var data = Data()
        for try await byte in bytes {
            guard data.count < Self.seriesCatalogueByteLimit else { throw ClientError.catalogueTooLarge }
            data.append(byte)
        }
        try Task.checkCancellation()
        return try SDMXParser.catalogue(data, dataset: dataset, structure: structure)
    }
    public static func observationsRequest(dataset: StatisticalDataset, key: String, fullHistory: Bool = false, now: Date = .now) throws -> URLRequest {
        guard !key.isEmpty, key != "all", key.count <= Self.maximumKeyLength,
              key.split(separator: ".", omittingEmptySubsequences: false).allSatisfy({ !$0.isEmpty }),
              key.range(of: "^[A-Za-z0-9_@.:-]+$", options: .regularExpression) != nil else { throw ClientError.invalidKey }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(byAdding: .year, value: -HistoryPeriod.recentYears, to: now)!
        let source = dataset.source
        if source == .newYorkFed {
            let route = dataset.metadata["ROUTE"] ?? "all"
            return request(source: source, path: "/\(route)/search.json?startDate=\(fullHistory ? Self.fullHistoryStart : day(start))&endDate=\(day(now))")
        }
        if source == .fred {
            return request(source: source, path: "/series/observations?series_id=\(component(key))&file_type=json" + (fullHistory ? "" : "&observation_start=\(day(start))"))
        }
        if source == .worldBank {
            let period = fullHistory ? "" : "&date=\(calendar.component(.year, from: start)):\(calendar.component(.year, from: now))"
            return request(source: source, path: "/country/\(component(key))/indicator/\(component(dataset.code))?format=json&per_page=20000\(period)&source=\(component(dataset.agency))")
        }
        return request(source: source, path: dataPath(dataset, key: key) + "?dimensionAtObservation=TIME_PERIOD&endPeriod=\(day(now))" + (fullHistory ? "" : "&startPeriod=\(day(start))"))
    }
    private static func dataPath(_ dataset: StatisticalDataset, key: String) -> String {
        let suffix = key.isEmpty ? "" : "/" + component(key)
        switch dataset.source {
        case .bis: return "/data/dataflow/\(component(dataset.agency))/\(component(dataset.code))/\(component(dataset.version))" + suffix
        case .oecd: return "/data/\(component(dataset.agency)),\(component(dataset.code)),\(component(dataset.version))" + suffix
        default: return "/data/\(component(dataset.code))" + suffix
        }
    }
    public func fetch(dataset: StatisticalDataset, structure: StatisticalStructure, key: String,
                      fullHistory: Bool = false, now: Date = .now) async throws -> MarketSeries {
        if dataset.source.isSDMX, key.split(separator: ".", omittingEmptySubsequences: false).count != structure.dimensions.count { throw ClientError.invalidKey }
        let request = try Self.observationsRequest(dataset: dataset, key: key, fullHistory: fullHistory, now: now)
        let data = try await download(request)
        if dataset.source == .fred {
            let metadata = try await download(Self.fredSeriesRequest(key: key))
            return try Self.fredSeries(observations: data, metadata: metadata, dataset: dataset, key: key, fullHistory: fullHistory, now: now)
        }
        return try Self.parse(data, dataset: dataset, structure: structure, key: key, fullHistory: fullHistory, now: now)
    }
    /// Loads the current observations of a chosen series, whatever its measurement; callers compare it themselves.
    public func observations(for descriptor: StatisticalSeriesDescriptor, fullHistory: Bool = false, now: Date = .now) async throws -> MarketSeries {
        // A FRED series is named by its own identifier: its release list is not needed to refresh it.
        let structure = descriptor.dataset.source == .fred ? StatisticalStructure(dimensions: [], labels: [:])
            : try await structure(dataset: descriptor.dataset)
        return try await fetch(dataset: descriptor.dataset, structure: structure, key: descriptor.key, fullHistory: fullHistory, now: now)
    }
    public func fetch(_ descriptor: StatisticalSeriesDescriptor, fullHistory: Bool = false, now: Date = .now) async throws -> MarketSeries {
        let value = try await observations(for: descriptor, fullHistory: fullHistory, now: now)
        guard let next = value.statisticalDescriptor, descriptor.usesSameMeasurement(as: next) else { throw ClientError.metadataChanged }
        return value
    }
    public static func parse(_ data: Data, dataset: StatisticalDataset, structure: StatisticalStructure, key: String,
                             fullHistory: Bool = false, now: Date = .now) throws -> MarketSeries {
        if dataset.source.isSDMX {
            let series = try SDMXParser.series(data, dataset: dataset, structure: structure, fullHistory: fullHistory, now: now)
            guard series.statisticalDescriptor?.key.caseInsensitiveCompare(key) == .orderedSame else { throw ClientError.invalidData }
            return series
        }
        if dataset.source == .newYorkFed { return try fedSeries(data, dataset: dataset, key: key, fullHistory: fullHistory, now: now) }
        if dataset.source == .fred { throw ClientError.invalidData } // Needs the series metadata too: use `fredSeries`.
        return try bankSeries(data, dataset: dataset, key: key, fullHistory: fullHistory, now: now)
    }

    private func download(_ request: URLRequest) async throws -> Data {
        var request = request
        let isFRED = request.url?.absoluteString.hasPrefix(StatisticalSource.fred.baseURL) == true
        if isFRED {
            // FRED documents only the `api_key` query parameter; the URL is never logged nor cached.
            guard let fredKey, !fredKey.isEmpty, let url = request.url,
                  var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw ClientError.missingAPIKey }
            components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "api_key", value: fredKey)]
            request.url = components.url
        }
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        if isFRED, (response as? HTTPURLResponse)?.statusCode == 400 { throw ClientError.rejectedAPIKey }
        try Self.validate(response)
        return data
    }

    /// Checks a FRED key with one small request before it is saved.
    public func validateFREDKey() async throws {
        _ = try await download(Self.fredSeriesRequest(key: "DGS10"))
    }
    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw ClientError.unavailable }
        if http.statusCode == 429 { throw ClientError.quotaReached }
        if http.statusCode == 204 || http.statusCode == 404 { throw ClientError.noData }
        guard http.statusCode == 200 else { throw ClientError.unavailable }
    }
    private static func request(source: StatisticalSource, path: String, structure: Bool = false) -> URLRequest {
        var request = URLRequest(url: URL(string: source.baseURL + path)!)
        request.timeoutInterval = Self.timeout
        request.setValue(source.isSDMX ? "application/vnd.sdmx.\(structure ? "structure" : "genericdata")+xml;version=2.1" : "application/json", forHTTPHeaderField: "Accept")
        return request
    }
    private static func component(_ text: String) -> String {
        text.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_@.-"))!
    }
    static func day(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }

    static func fedDatasets(_ data: Data) throws -> [StatisticalDataset] {
        let rows = try fedRows(data)
        return rows.compactMap { row in
            guard let type = row["type"]?.text else { return nil }
            var metadata: [String: String] = [:]
            for (key, value) in row {
                if case .number = value { metadata["MEASURE:\(key)"] = fedLabel(key) }
            }
            // Unknown future types remain accessible through the documented all-rates endpoint.
            metadata["ROUTE"] = ["EFFR", "OBFR"].contains(type) ? "unsecured/\(type.lowercased())" : ["SOFR", "SOFRAI", "BGCR", "TGCR"].contains(type) ? "secured/\(type.lowercased())" : "all"
            return .init(source: .newYorkFed, code: type, agency: "NYFED", version: "1", title: type,
                detail: "Taux de référence et mesures publiées · choisir la mesure, sans confondre taux effectif et cible.", metadata: metadata)
        }.sorted { $0.code < $1.code }
    }
    private static func fedRows(_ data: Data) throws -> [[String: WebstatValue]] {
        guard let root = try? JSONDecoder().decode([String: WebstatValue].self, from: data),
              case .array(let values) = root["refRates"] else { throw ClientError.invalidData }
        return values.compactMap { if case .object(let row) = $0 { row } else { nil } }
    }
    private static func fedLabel(_ key: String) -> String {
        switch key {
        case "percentRate": "Taux effectif"
        case "targetRateFrom": "Cible Fed · borne basse"
        case "targetRateTo": "Cible Fed · borne haute"
        case "volumeInBillions": "Volume · milliards de dollars"
        case "average30day": "Moyenne composée · 30 jours"
        case "average90day": "Moyenne composée · 90 jours"
        case "average180day": "Moyenne composée · 180 jours"
        case "index": "Indice SOFR"
        default: key.hasPrefix("percentPercentile") ? "Percentile \(key.dropFirst(17))" : key
        }
    }
    private static func fedSeries(_ data: Data, dataset: StatisticalDataset, key: String, fullHistory: Bool, now: Date) throws -> MarketSeries {
        let rows = try fedRows(data).filter { $0["type"]?.text == dataset.code }
        let points = rows.compactMap { row -> MarketObservation? in
            guard let dateText = row["effectiveDate"]?.text, let period = SDMXParser.period(dateText), period.start <= now,
                  let raw = row[key]?.text, let value = SDMXParser.decimal(raw) else { return nil }
            return .init(date: period.start, value: value, status: row["revisionIndicator"]?.text.flatMap { $0.isEmpty ? nil : "Révisée (\($0))" })
        }
        guard !points.isEmpty else { throw ClientError.noData }
        var fields = ["TITLE": "\(dataset.code) · \(fedLabel(key))", "FREQ": "B", "DECIMALS": key == "index" ? "8" : "2"]
        if key.hasPrefix("percent") || key.hasPrefix("average") || ["targetRateFrom", "targetRateTo"].contains(key) { fields["UNIT"] = "PC"; fields["UNIT_MULT"] = "0" }
        if key == "index" { fields["UNIT"] = "IX"; fields["UNIT_MULT"] = "0" }
        if key == "volumeInBillions" { fields["UNIT"] = "USD"; fields["UNIT_MULT"] = "9" }
        let descriptor = StatisticalSeriesDescriptor(dataset: dataset, key: key, dimensionIDs: ["MEASURE"], fields: fields, labels: [:])
        return descriptor.series(observations: points, syncedAt: now, completeHistory: fullHistory)
    }

    private static func bankResponse(_ data: Data) throws -> ([String: WebstatValue], [[String: WebstatValue]]) {
        guard let response = try? JSONDecoder().decode([WebstatValue].self, from: data), response.count == 2,
              case .object(let metadata) = response[0], case .array(let rows) = response[1] else { throw ClientError.invalidData }
        return (metadata, rows.compactMap { if case .object(let row) = $0 { row } else { nil } })
    }
    private static func bankDatasets(_ rows: [[String: WebstatValue]]) -> [StatisticalDataset] {
        rows.compactMap { row in
            guard let code = row["id"]?.text, let title = row["name"]?.text,
                  case .object(let source) = row["source"], let sourceID = source["id"]?.text else { return nil }
            return .init(source: .worldBank, code: code, agency: sourceID, version: "2", title: title,
                detail: row["sourceNote"]?.text ?? "", metadata: ["UNIT": row["unit"]?.text ?? "", "PRODUCER": row["sourceOrganization"]?.text ?? ""])
        }
    }
    private static func bankSeries(_ data: Data, dataset: StatisticalDataset, key: String, fullHistory: Bool, now: Date) throws -> MarketSeries {
        let (metadata, rows) = try bankResponse(data)
        guard (Int(metadata["pages"]?.text ?? "1") ?? 1) <= 1 else { throw ClientError.invalidData }
        var frequencies: Set<String> = []
        let points = try rows.compactMap { row -> MarketObservation? in
            guard let time = row["date"]?.text, let value = row["value"]?.text.flatMap(SDMXParser.decimal) else { return nil }
            let normalized: String
            if time.range(of: "^[0-9]{4}M[0-9]{2}$", options: .regularExpression) != nil {
                normalized = "\(time.prefix(4))-\(time.suffix(2))"; frequencies.insert("M")
            } else if time.range(of: "^[0-9]{4}Q[1-4]$", options: .regularExpression) != nil {
                normalized = "\(time.prefix(4))-Q\(time.suffix(1))"; frequencies.insert("Q")
            } else {
                normalized = time; frequencies.insert(time.count == 4 ? "A" : time.count == 7 && time.contains("Q") ? "Q" : time.count == 7 ? "M" : "D")
            }
            guard let period = SDMXParser.period(normalized) else { throw ClientError.unsupportedPeriod }
            guard period.start <= now else { return nil }
            return .init(date: period.start, value: value, periodEnd: period.end)
        }
        guard !points.isEmpty else { throw ClientError.noData }
        guard frequencies.count == 1 else { throw ClientError.chooseOneSeries }
        let canonicalCountry = rows.compactMap { $0["countryiso3code"]?.text }.first(where: { !$0.isEmpty }) ?? key
        var fields = ["TITLE": dataset.title, "REF_AREA": canonicalCountry, "FREQ": frequencies.first!, "PRODUCER": dataset.metadata["PRODUCER"] ?? ""]
        var labels: [String: String] = [:]
        if let unit = dataset.metadata["UNIT"], !unit.isEmpty { fields["UNIT"] = unit == "%" ? "PC" : unit; fields["UNIT_MULT"] = "0"; labels["UNIT"] = unit }
        if let first = rows.first, case .object(let country) = first["country"] { labels["REF_AREA"] = country["value"]?.text }
        let descriptor = StatisticalSeriesDescriptor(dataset: dataset, key: canonicalCountry, dimensionIDs: ["REF_AREA"], fields: fields, labels: labels)
        return descriptor.series(observations: points, syncedAt: now, completeHistory: fullHistory)
    }

    // MARK: FRED

    static func fredReleaseSeriesRequest(_ dataset: StatisticalDataset) -> URLRequest {
        request(source: .fred, path: "/release/series?release_id=\(component(dataset.code))&file_type=json&limit=\(fredPageLimit)&order_by=popularity&sort_order=desc")
    }
    static func fredSeriesRequest(key: String) -> URLRequest {
        request(source: .fred, path: "/series?series_id=\(component(key))&file_type=json")
    }
    private static func fredObject(_ data: Data) throws -> [String: WebstatValue] {
        guard let root = try? JSONDecoder().decode([String: WebstatValue].self, from: data) else { throw ClientError.invalidData }
        return root
    }
    private static func fredRows(_ data: Data, key: String) throws -> [[String: WebstatValue]] {
        guard case .array(let values) = try fredObject(data)[key] else { throw ClientError.invalidData }
        return values.compactMap { if case .object(let row) = $0 { row } else { nil } }
    }
    static func fredDatasets(_ data: Data) throws -> [StatisticalDataset] {
        try fredRows(data, key: "releases").compactMap { row in
            guard let id = row["id"]?.text, let name = row["name"]?.text else { return nil }
            return .init(source: .fred, code: id, agency: "FRED", version: "1", title: name, detail: row["notes"]?.text ?? "")
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
    static func fredSeriesCodes(_ data: Data) throws -> [StatisticalCode] {
        try fredRows(data, key: "seriess").compactMap { row in
            guard let id = row["id"]?.text, let title = row["title"]?.text else { return nil }
            let detail = [row["units_short"]?.text, row["frequency_short"]?.text].compactMap { $0 }.joined(separator: " · ")
            return .init(id: id, title: detail.isEmpty ? title : "\(title) · \(detail)")
        }
    }
    /// FRED units become the same unit codes as the other sources, so alerts and variations follow one contract.
    static func fredUnit(_ units: String) -> (code: String, multiplier: String) {
        let text = units.lowercased()
        if text.hasPrefix("percent") { return ("PC", "0") }
        if text.hasPrefix("index") { return ("IX", "0") }
        if text.hasPrefix("billions of u.s. dollars") || text.hasPrefix("billions of dollars") { return ("USD", "9") }
        if text.hasPrefix("millions of u.s. dollars") || text.hasPrefix("millions of dollars") { return ("USD", "6") }
        if text.hasPrefix("u.s. dollars") { return ("USD", "0") }
        return (units, "0")
    }
    public static func fredSeries(observations: Data, metadata: Data, dataset: StatisticalDataset, key: String,
                                  fullHistory: Bool = false, now: Date = .now) throws -> MarketSeries {
        guard let info = try fredRows(metadata, key: "seriess").first, info["id"]?.text?.caseInsensitiveCompare(key) == .orderedSame,
              let title = info["title"]?.text else { throw ClientError.invalidData }
        let points = try fredRows(observations, key: "observations").compactMap { row -> MarketObservation? in
            // FRED marks a missing value with ".", for example on a market holiday.
            guard let dateText = row["date"]?.text, let period = SDMXParser.period(dateText), period.start <= now,
                  let raw = row["value"]?.text, raw != ".", let value = SDMXParser.decimal(raw) else { return nil }
            return .init(date: period.start, value: value)
        }
        guard !points.isEmpty else { throw ClientError.noData }
        let units = info["units"]?.text ?? ""
        let unit = fredUnit(units)
        let frequency = info["frequency_short"]?.text ?? ""
        let fields = ["TITLE": title, "FREQ": frequency == "D" ? "B" : frequency, "UNIT": unit.code, "UNIT_MULT": unit.multiplier,
                      "DECIMALS": "2", "TITLE_COMPL": info["notes"]?.text ?? dataset.detail]
        let canonical = info["id"]?.text ?? key
        let descriptor = StatisticalSeriesDescriptor(dataset: dataset, key: canonical, dimensionIDs: ["SERIES"], fields: fields,
                                                     labels: ["UNIT": units])
        return descriptor.series(observations: points, syncedAt: now, completeHistory: fullHistory)
    }
}
