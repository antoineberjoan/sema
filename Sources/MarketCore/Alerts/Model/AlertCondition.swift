// Distingue un seuil en niveau, une variation relative héritée des fonds et un mouvement inhabituel.
import Foundation

public enum AlertCondition: String, Codable, Sendable {
    case relativeChange, level
    /// Variation de séance comparée à la variation habituelle ; les deux directions, sensibilité globale.
    case unusualMove
}
