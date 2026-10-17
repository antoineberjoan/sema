// Producteurs statistiques publics pris en charge, leurs adresses et leurs formats.
import Foundation

public enum StatisticalSource: String, Codable, CaseIterable, Sendable, Identifiable {
    case insee, ecb, eurostat, bis, oecd, newYorkFed, worldBank
    public var id: String { rawValue }
    public var title: String {
        switch self { case .insee: "Insee"; case .ecb: "BCE"; case .eurostat: "Eurostat"
        case .bis: "BRI"; case .oecd: "OCDE"; case .newYorkFed: "Fed de New York"; case .worldBank: "Banque mondiale" }
    }
    public var isSDMX: Bool { ![.newYorkFed, .worldBank].contains(self) }
    public var baseURL: String {
        switch self {
        case .insee: "https://bdm.insee.fr/series/sdmx"
        case .ecb: "https://data-api.ecb.europa.eu/service"
        case .eurostat: "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1"
        case .bis: "https://stats.bis.org/api/v2"
        case .oecd: "https://sdmx.oecd.org/public/rest/v1"
        case .newYorkFed: "https://markets.newyorkfed.org/api/rates"
        case .worldBank: "https://api.worldbank.org/v2"
        }
    }
    public var website: URL {
        let address = switch self {
        case .insee: "https://www.insee.fr/fr/statistiques"
        case .ecb: "https://data.ecb.europa.eu"
        case .eurostat: "https://ec.europa.eu/eurostat/databrowser"
        case .bis: "https://data.bis.org"
        case .oecd: "https://data-explorer.oecd.org"
        case .newYorkFed: "https://www.newyorkfed.org/markets/reference-rates"
        case .worldBank: "https://data.worldbank.org"
        }
        return URL(string: address)!
    }
    public var termsURL: URL {
        let address = switch self {
        case .insee: "https://www.insee.fr/fr/information/2008466"
        case .ecb: "https://www.ecb.europa.eu/stats/ecb_statistics/governance_and_quality_framework/html/usage_policy.en.html"
        case .eurostat: "https://ec.europa.eu/eurostat/help/copyright-notice"
        case .bis: "https://www.bis.org/about/legal/permitted-use-statistics"
        case .oecd: "https://www.oecd.org/en/about/terms-conditions.html"
        case .newYorkFed: "https://www.newyorkfed.org/privacy/termsofuse.html"
        case .worldBank: "https://data.worldbank.org/summary-terms-of-use"
        }
        return URL(string: address)!
    }
    public var scope: String {
        switch self {
        case .newYorkFed: "Taux de référence, moyennes, indices, percentiles et volumes publiés. Les opérations de marché ne sont pas des séries de taux et ne sont pas intégrées ici."
        case .worldBank: "Catalogue des indicateurs publics · choix du pays ou de l’agrégat."
        default: "Catalogue publié par la source · choisissez un jeu puis une combinaison de dimensions."
        }
    }
    public var attribution: String {
        switch self {
        case .insee: "Source : Insee. Licence Ouverte 2.0, sauf mention contraire."
        case .ecb: "Source : statistiques BCE. Les données de tiers restent soumises aux droits de leur producteur."
        case .eurostat: "Source : Eurostat. Les données de tiers et certaines données hors Europe ont des conditions de réutilisation spécifiques."
        case .bis: "Source : BRI. L’inclusion de ces statistiques dans un produit ne doit pas entraîner de supplément facturé à l’utilisateur."
        case .oecd: "Source : OCDE. Vérifier les restrictions propres au jeu et aux données de tiers."
        case .worldBank: "Source : Banque mondiale. CC BY 4.0, sauf restrictions indiquées pour les données de tiers."
        case .newYorkFed: "The reference rate data is subject to the Terms of Use posted at newyorkfed.org. The New York Fed is not responsible for publication of the reference rate data by Sema, does not endorse any particular republication, and has no liability for your use. Sema is not affiliated with the New York Fed. The New York Fed does not sanction, endorse, or recommend any products or services offered by Sema."
        }
    }
}
