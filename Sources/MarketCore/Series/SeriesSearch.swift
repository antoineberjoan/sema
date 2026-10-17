// Recherche dans les séries locales avec normalisation et synonymes des repères connus.
import Foundation

public enum SeriesSearch {
    /// Local search only. Aliases name the integrated series, never a different benchmark.
    public static func results(in series: [MarketSeries], query: String) -> [MarketSeries] {
        let tokens = normalize(query).split(separator: " ")
        return series.filter { item in
            guard item.category != .funds else { return false }
            let text = normalize([item.name, item.subtitle, item.id, item.displayUnit, item.descriptor?.definition ?? "", aliases[item.id] ?? aliases.first(where: { WebstatClient.canonicalID($0.key) == item.id })?.value ?? ""].joined(separator: " "))
            return tokens.allSatisfy { text.contains($0) }
        }
    }

    private static let aliases = [
        "fr10": "OAT France français dix ans emprunt phare obligataire rendement mensuel",
        "ecb": "BCE Banque centrale européenne facilité dépôt taux directeur",
        "estr": "ESTR euro short term monétaire",
        "mortgage-fr": "crédit immobilier immo emprunt prêt habitat logement",
        "inflation": "inflation France prix IPCH",
        "inflation-euro": "inflation zone euro prix IPCH",
        "eurusd": "change dollar américain USD",
        "eurjpy": "change yen japonais JPY",
        "eurchf": "change franc suisse CHF",
        "eurgbp": "change livre sterling GBP",
        "livreta": "livret A épargne réglementée",
        "ldds": "livret développement durable solidaire épargne",
        "lep": "livret épargne populaire"
    ]

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "fr_FR"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
    }
}
