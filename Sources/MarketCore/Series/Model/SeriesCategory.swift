// Famille d’usage d’une série : marchés, épargne ou fonds.
import Foundation

public enum SeriesCategory: String, Codable, CaseIterable, Sendable {
    case markets, savings, funds
}
