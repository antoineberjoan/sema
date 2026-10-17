// Rythme de publication d’une série et son libellé.
import Foundation

public enum ObservationFrequency: String, Codable, Sendable {
    case daily, businessDaily, weekly, monthly, quarterly, halfYearly, yearly, unknown

    public var title: String {
        switch self {
        case .daily: "Quotidien"
        case .businessDaily: "Jours ouvrés"
        case .weekly: "Hebdomadaire"
        case .monthly: "Mensuel"
        case .quarterly: "Trimestriel"
        case .halfYearly: "Semestriel"
        case .yearly: "Annuel"
        case .unknown: "Fréquence non interprétée"
        }
    }
}
