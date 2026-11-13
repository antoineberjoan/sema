// Parle au protocole SDMX de cinq producteurs (Insee, BCE, Eurostat, BRI, OCDE) : l'hôte est le paramètre `source`.
import Foundation

/// Hôtes servis : `StatisticalSource.sdmxSources`. Un hôte dont les réponses demandent leur propre décodage devient son connecteur.
public struct SdmxClient: StatisticalConnector {
    /// Borne l’arbre XML et la liste gardée en mémoire ; ne présente jamais un catalogue tronqué.
    private static let seriesCatalogueByteLimit = 20 * 1024 * 1024
    public let source: StatisticalSource

    public init(source: StatisticalSource) {
        precondition(source.isSDMX, "SdmxClient ne sert que les sources SDMX")
        self.source = source
    }

    public static func catalogueRequest(_ source: StatisticalSource) -> URLRequest {
        let path: String
        switch source {
        case .insee: path = "/dataflow"
        case .ecb: path = "/dataflow/ECB/all/latest?references=none"
        case .eurostat: path = "/dataflow/ESTAT/all/latest?references=none"
        case .bis: path = "/structure/dataflow/BIS/all/latest?references=none"
        default: path = "/dataflow/all/all/latest?references=none"
        }
        return request(source: source, path: path, structure: true)
    }

    public func datasets() async throws -> [StatisticalDataset] {
        let (data, response) = try await PublicDataTransport.send(Self.catalogueRequest(source))
        try PublicDataTransport.validate(response)
        return try SDMXParser.datasets(data, source: source)
    }

    public func structure(dataset: StatisticalDataset) async throws -> StatisticalStructure {
        let (data, response) = try await PublicDataTransport.send(Self.structureRequest(dataset))
        try PublicDataTransport.validate(response)
        let structure = try SDMXParser.structure(data, dataset: dataset)
        var additional: [Data] = []
        for reference in structure.missingCodelists {
            try Task.checkCancellation()
            let prefix = dataset.source == .bis ? "/structure" : ""
            let component = PublicDataTransport.component
            let path = "\(prefix)/codelist/\(component(reference.agency))/\(component(reference.code))/\(component(reference.version))"
            do {
                let (codelist, answer) = try await PublicDataTransport.send(Self.request(source: dataset.source, path: path, structure: true))
                try PublicDataTransport.validate(answer)
                additional.append(codelist)
            }
            catch is CancellationError { throw CancellationError() }
            catch PublicDataError.quotaReached { throw PublicDataError.quotaReached }
            catch { } // Une liste de codes indisponible laisse un champ de code explicite ; les observations restent accessibles.
        }
        return additional.isEmpty ? structure : try SDMXParser.structure(data, dataset: dataset, additionalCodelists: additional)
    }

    public static func structureRequest(_ dataset: StatisticalDataset) -> URLRequest {
        let source = dataset.source
        let component = PublicDataTransport.component
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
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(for: Self.seriesCatalogueRequest(dataset))
        try PublicDataTransport.validate(response)
        guard response.expectedContentLength <= Int64(Self.seriesCatalogueByteLimit) else { throw PublicDataError.catalogueTooLarge }
        var data = Data()
        for try await byte in bytes {
            guard data.count < Self.seriesCatalogueByteLimit else { throw PublicDataError.catalogueTooLarge }
            data.append(byte)
        }
        try Task.checkCancellation()
        return try SDMXParser.catalogue(data, dataset: dataset, structure: structure)
    }

    public static func observationsRequest(dataset: StatisticalDataset, key: String, fullHistory: Bool = false, now: Date = .now) throws -> URLRequest {
        try PublicDataTransport.validateKey(key)
        let start = PublicDataTransport.historyStart(endingAt: now).start
        let day = PublicDataTransport.day
        return request(source: dataset.source, path: dataPath(dataset, key: key) + "?dimensionAtObservation=TIME_PERIOD&endPeriod=\(day(now))" + (fullHistory ? "" : "&startPeriod=\(day(start))"))
    }

    private static func dataPath(_ dataset: StatisticalDataset, key: String) -> String {
        let component = PublicDataTransport.component
        let suffix = key.isEmpty ? "" : "/" + component(key)
        switch dataset.source {
        case .bis: return "/data/dataflow/\(component(dataset.agency))/\(component(dataset.code))/\(component(dataset.version))" + suffix
        case .oecd: return "/data/\(component(dataset.agency)),\(component(dataset.code)),\(component(dataset.version))" + suffix
        default: return "/data/\(component(dataset.code))" + suffix
        }
    }

    public func fetch(dataset: StatisticalDataset, structure: StatisticalStructure, key: String,
                      fullHistory: Bool, now: Date) async throws -> MarketSeries {
        if key.split(separator: ".", omittingEmptySubsequences: false).count != structure.dimensions.count { throw PublicDataError.invalidKey }
        let (data, response) = try await PublicDataTransport.send(try Self.observationsRequest(dataset: dataset, key: key, fullHistory: fullHistory, now: now))
        try PublicDataTransport.validate(response)
        return try Self.parse(data, dataset: dataset, structure: structure, key: key, fullHistory: fullHistory, now: now)
    }

    public static func parse(_ data: Data, dataset: StatisticalDataset, structure: StatisticalStructure, key: String,
                             fullHistory: Bool = false, now: Date = .now) throws -> MarketSeries {
        let series = try SDMXParser.series(data, dataset: dataset, structure: structure, fullHistory: fullHistory, now: now)
        guard series.statisticalDescriptor?.key.caseInsensitiveCompare(key) == .orderedSame else { throw PublicDataError.invalidData }
        return series
    }

    private static func request(source: StatisticalSource, path: String, structure: Bool = false) -> URLRequest {
        PublicDataTransport.request(source.baseURL + path, accept: "application/vnd.sdmx.\(structure ? "structure" : "genericdata")+xml;version=2.1")
    }
}
