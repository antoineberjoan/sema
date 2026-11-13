// Erreurs propres à Webstat, sans adresse ni clé ; les causes communes à toutes les sources sont dans `PublicDataError`.
import Foundation

public enum WebstatError: Error, LocalizedError, Equatable {
    case missingKey, accessDenied, incompleteData

    public var errorDescription: String? {
        switch self {
        case .missingKey: "Ajoutez votre clé Webstat dans les réglages."
        case .accessDenied: "Accès Webstat refusé. Vérifiez votre clé et ses autorisations."
        case .incompleteData: "Webstat n’a pas fourni les données attendues. Les observations précédentes sont conservées."
        }
    }
}
