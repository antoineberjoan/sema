// Distingue un seuil en niveau, une variation relative héritée des fonds et un mouvement inhabituel.
import Foundation

public enum AlertCondition: String, Codable, Sendable {
    case relativeChange, level
    /// Session change compared with the usual variation; both directions, global sensitivity.
    case unusualMove
}
