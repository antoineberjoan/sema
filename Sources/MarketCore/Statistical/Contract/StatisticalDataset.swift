// Jeu de données publié par un producteur, identifié par son agence et sa version.
import Foundation

public struct StatisticalDataset: Codable, Equatable, Sendable, Identifiable {
    public let source: StatisticalSource
    public let code: String
    public let agency: String
    public let version: String
    public let title: String
    public let detail: String
    public let metadata: [String: String]
    public var id: String { "\(source.rawValue):\(agency):\(code):\(version)" }
    public init(source: StatisticalSource, code: String, agency: String, version: String,
                title: String, detail: String, metadata: [String: String] = [:]) {
        self.source = source; self.code = code; self.agency = agency; self.version = version
        self.title = title; self.detail = detail; self.metadata = metadata
    }
}
