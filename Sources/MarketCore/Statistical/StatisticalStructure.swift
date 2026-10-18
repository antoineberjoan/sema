// Dimensions et libellés d’un jeu, avec les listes de codes encore à charger.
import Foundation

public struct StatisticalStructure: Codable, Equatable, Sendable {
    public let dimensions: [StatisticalDimension]
    public let labels: [String: [String: String]]
    public var missingCodelists: [StatisticalCodelistReference] = []
    public func key(values: [String: String]) -> String {
        dimensions.map { values[$0.id] ?? "" }.joined(separator: ".")
    }
}
