// Référence versionnée d’une liste de codes à charger séparément.
import Foundation

public struct StatisticalCodelistReference: Codable, Hashable, Sendable {
    public let agency: String
    public let code: String
    public let version: String
}
