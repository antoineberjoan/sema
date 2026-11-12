// Erreurs nommées de Webstat, sans adresse ni clé.
import Foundation

public enum WebstatError: Error, LocalizedError {
    case missingKey, accessDenied, quotaReached, unavailable, invalidData, incompleteData, metadataChanged

    public var errorDescription: String? {
        switch self {
        case .missingKey: "Ajoutez votre clé Webstat dans les réglages."
        case .accessDenied: "Accès Webstat refusé. Vérifiez votre clé et ses autorisations."
        case .quotaReached: "Le quota Webstat est atteint. Réessayez le lendemain."
        case .unavailable: "La connexion à Webstat a échoué. Réessayez plus tard."
        case .invalidData: "Le format des données Webstat n’a pas pu être lu."
        case .incompleteData: "Webstat n’a pas fourni les données attendues. Les observations précédentes sont conservées."
        case .metadataChanged: "L’unité, l’échelle ou la base de cette série a changé. Actualisez le repère avant de recharger son historique."
        }
    }
}
