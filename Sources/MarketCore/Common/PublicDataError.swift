// Erreurs que les connecteurs de données publiques, de presse et de contexte rendent à l'app.
import Foundation

public enum PublicDataError: Error, LocalizedError {
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
