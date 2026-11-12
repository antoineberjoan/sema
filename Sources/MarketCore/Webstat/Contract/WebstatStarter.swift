// Repères de départ de Webstat, lus dans `Starters/webstat.json` : leurs valeurs viennent toujours de Webstat.
import Foundation

public enum WebstatStarter {
    /// Une ligne du fichier `Starters/webstat.json`.
    struct Definition: Decodable, Sendable {
        /// Nom de départ propre au produit (« fr10 », « eurusd »), clé des règles de lecture et de la recherche.
        let slug: String
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

    /// Code de série Webstat de chaque nom de départ.
    public static var keysBySlug: [String: String] {
        Dictionary(uniqueKeysWithValues: definitions.map { ($0.slug, $0.seriesCode) })
    }
    /// Code de série d'un nom de départ ; un code de série reste tel quel.
    public static func starterKey(_ slug: String) -> String { keysBySlug[slug] ?? slug }
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
