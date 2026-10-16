import Foundation

/// Catalogue discovery is independent of observations: no bulk download of every time series.
public struct StatisticalClient: Sendable {
    public enum ClientError: Error, LocalizedError {
        case unavailable, quotaReached, invalidData, noData, metadataChanged, chooseOneSeries, invalidKey, unsupportedPeriod
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
            }
        }
    }
    public init() {}

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
        }
        return request(source: source, path: path, structure: true)
    }
    public func datasets(source: StatisticalSource) async throws -> [StatisticalDataset] {
        let data = try await download(Self.catalogueRequest(source))
        if source.isSDMX { return try SDMXParser.datasets(data, source: source) }
        if source == .newYorkFed { return try Self.fedDatasets(data) }
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
            let fields = dataset.metadata.keys.filter { $0.hasPrefix("MEASURE:") }.sorted()
            return .init(dimensions: [.init(id: "MEASURE", title: "Mesure", position: 1,
                codes: fields.map { .init(id: String($0.dropFirst(8)), title: dataset.metadata[$0]!) })], labels: [:])
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
    public static func observationsRequest(dataset: StatisticalDataset, key: String, fullHistory: Bool = false, now: Date = .now) throws -> URLRequest {
        guard !key.isEmpty, key != "all", key.count <= 1000,
              key.split(separator: ".", omittingEmptySubsequences: false).allSatisfy({ !$0.isEmpty }),
              key.range(of: "^[A-Za-z0-9_@.:-]+$", options: .regularExpression) != nil else { throw ClientError.invalidKey }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(byAdding: .year, value: -6, to: now)!
        let source = dataset.source
        if source == .newYorkFed {
            let route = dataset.metadata["ROUTE"] ?? "all"
            return request(source: source, path: "/\(route)/search.json?startDate=\(fullHistory ? "2000-01-01" : day(start))&endDate=\(day(now))")
        }
        if source == .worldBank {
            let period = fullHistory ? "" : "&date=\(calendar.component(.year, from: start)):\(calendar.component(.year, from: now))"
            return request(source: source, path: "/country/\(component(key))/indicator/\(component(dataset.code))?format=json&per_page=20000\(period)&source=\(component(dataset.agency))")
        }
        let path: String
        switch source {
        case .insee: path = "/data/\(component(dataset.code))/\(component(key))"
        case .bis: path = "/data/dataflow/\(component(dataset.agency))/\(component(dataset.code))/\(component(dataset.version))/\(component(key))"
        case .oecd: path = "/data/\(component(dataset.agency)),\(component(dataset.code)),\(component(dataset.version))/\(component(key))"
        default: path = "/data/\(component(dataset.code))/\(component(key))"
        }
        return request(source: source, path: path + "?dimensionAtObservation=TIME_PERIOD&endPeriod=\(day(now))" + (fullHistory ? "" : "&startPeriod=\(day(start))"))
    }
    public func fetch(dataset: StatisticalDataset, structure: StatisticalStructure, key: String,
                      fullHistory: Bool = false, now: Date = .now) async throws -> MarketSeries {
        if dataset.source.isSDMX, key.split(separator: ".", omittingEmptySubsequences: false).count != structure.dimensions.count { throw ClientError.invalidKey }
        let request = try Self.observationsRequest(dataset: dataset, key: key, fullHistory: fullHistory, now: now)
        let data = try await download(request)
        return try Self.parse(data, dataset: dataset, structure: structure, key: key, fullHistory: fullHistory, now: now)
    }
    public func fetch(_ descriptor: StatisticalSeriesDescriptor, fullHistory: Bool = false, now: Date = .now) async throws -> MarketSeries {
        let structure = try await structure(dataset: descriptor.dataset)
        let value = try await fetch(dataset: descriptor.dataset, structure: structure, key: descriptor.key, fullHistory: fullHistory, now: now)
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
        return try bankSeries(data, dataset: dataset, key: key, fullHistory: fullHistory, now: now)
    }

    private func download(_ request: URLRequest) async throws -> Data {
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse else { throw ClientError.unavailable }
        if http.statusCode == 429 { throw ClientError.quotaReached }
        if http.statusCode == 204 || http.statusCode == 404 { throw ClientError.noData }
        guard http.statusCode == 200 else { throw ClientError.unavailable }
        return data
    }
    private static func request(source: StatisticalSource, path: String, structure: Bool = false) -> URLRequest {
        var request = URLRequest(url: URL(string: source.baseURL + path)!)
        request.timeoutInterval = 45
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
}
