// Repères de départ de Webstat, lus dans `Starters/webstat.json` : leurs valeurs viennent toujours de Webstat.
import Foundation

public enum WebstatStarter {
    /// Une ligne du fichier `Starters/webstat.json`.
    struct Definition: Decodable, Sendable {
        let id: String
        let seriesCode: String
        let name: String
        let subtitle: String
        let category: SeriesCategory
        let unit: ValueUnit
        let digits: Int
        let frequency: ObservationFrequency
        let producer: String
    }

    static let definitions = StarterResources.load([Definition].self, file: "webstat")

    public static var shortIDs: [String: String] {
        Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0.seriesCode) })
    }
    public static func canonicalID(_ id: String) -> String { shortIDs[id] ?? id }
    public static var ids: [String] { definitions.map(\.seriesCode) }
    /// Repères sans observation : leurs valeurs viennent de Webstat, jamais d’un exemple.
    public static var series: [MarketSeries] {
        definitions.map { definition in
            MarketSeries(id: definition.seriesCode, name: definition.name, subtitle: definition.subtitle,
                category: definition.category, unit: definition.unit, fractionDigits: definition.digits,
                source: definition.producer, frequency: definition.frequency, observations: [])
        }
    }
}
