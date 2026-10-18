// Distingue un seuil en niveau d’un seuil en variation relative.
import Foundation

public enum AlertCondition: String, Codable, Sendable {
    case relativeChange, level
}
