// Références de départ exactes, à résoudre contre le catalogue vivant de chaque source.
import Foundation

public struct StatisticalStarter: Equatable, Sendable, Identifiable {
    public let source: StatisticalSource
    public let agency: String?
    public let datasetCode: String
    public let key: String
    /// Libellé de navigation ; l’aperçu conserve toujours le titre officiel du fournisseur.
    public let title: String

    public var id: String { "\(source.rawValue):\(agency ?? ""):\(datasetCode):\(key)" }

    public func matches(_ dataset: StatisticalDataset) -> Bool {
        dataset.source == source && dataset.code == datasetCode && (agency == nil || dataset.agency == agency)
    }

    /// Une ligne du fichier `Starters/statistical.json`, rangée par source.
    private struct Row: Decodable, Sendable {
        let agency: String?
        let dataset: String
        let series: String
        let title: String
    }

    private static let rows = StarterResources.load([String: [Row]].self, file: "statistical")

    public static func recommendations(for source: StatisticalSource) -> [StatisticalStarter] {
        (rows[source.rawValue] ?? []).map {
            .init(source: source, agency: $0.agency, datasetCode: $0.dataset, key: $0.series, title: $0.title)
        }
    }
}
