// Dimension d’un jeu de données, ordonnée selon la clé de série.
import Foundation

public struct StatisticalDimension: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let position: Int
    public let codes: [StatisticalCode]
}
