// Valeur codée d’une dimension et son libellé officiel.
import Foundation

public struct StatisticalCode: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
}
