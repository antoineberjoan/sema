// Fournit des erreurs de connexion expurgées des URL, clés et réponses brutes des fournisseurs.
import Foundation

public enum MarketDataError: Error, LocalizedError, Equatable {
    case missingKey, invalidKey, quota, entitlement, unavailable, invalidData, network, unknownPlan
    public var errorDescription: String? {
        switch self {
        case .unknownPlan: "Le fournisseur ne précise pas votre forfait. Le catalogue accessible ne peut pas être déterminé. Consultez votre compte fournisseur."
        case .missingKey: "Connectez votre clé dans les réglages Sources."
        case .invalidKey: "La clé n’est pas reconnue par le fournisseur."
        case .quota: "Le quota du fournisseur est atteint. Les données précédentes sont conservées."
        case .entitlement: "Ces données nécessitent un accès supplémentaire chez le fournisseur."
        case .unavailable: "Aucune donnée disponible pour cet instrument et cette fréquence."
        case .invalidData: "La réponse du fournisseur n’a pas pu être interprétée."
        case .network: "La connexion au fournisseur a échoué. Les données précédentes sont conservées."
        }
    }
}
