// Repères de départ de Webstat, lus dans `Starters/webstat.json` : leurs valeurs viennent toujours de Webstat.
import Foundation

public enum WebstatStarter {
    /// Une ligne du fichier `Starters/webstat.json`.
    struct Definition: Decodable, Sendable {
        /// Nom court d'un repère de départ (« fr10 », « eurusd ») : un fichier écrit par une version publiée peut le porter (`IdentifierMigration`).
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

    /// Code de série Webstat de chaque nom de départ, lu seulement par `IdentifierMigration`.
    static var keysBySlug: [String: String] {
        Dictionary(uniqueKeysWithValues: definitions.map { ($0.slug, $0.seriesCode) })
    }
    public static var ids: [String] { definitions.map(\.seriesCode) }
    /// Les repères de départ d'abord, dans l'ordre du fichier, puis le reste des résultats.
    public static func placingFirst(_ results: [WebstatSeriesDescriptor]) -> [WebstatSeriesDescriptor] {
        let starters = definitions.compactMap { definition in results.first { $0.key == definition.seriesCode } }
        let keys = Set(starters.map(\.key))
        return starters + results.filter { !keys.contains($0.key) }
    }

    /// Repères sans observation : leurs valeurs viennent de Webstat, jamais d’un exemple.
    public static var series: [MarketSeries] {
        definitions.map { definition in
            MarketSeries(id: definition.seriesCode, name: definition.name, subtitle: definition.subtitle,
                category: definition.category, unit: definition.unit, fractionDigits: definition.digits,
                source: definition.producer, frequency: definition.frequency, observations: [])
        }
    }
}
