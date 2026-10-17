// Normalise les réglages du verre indépendamment de la palette et du mode d’affichage.
import Foundation

/// Appearance of the ribbon surfaces, independent of the palette and display mode.
public struct RibbonGlassPreferences: Codable, Equatable, Sendable {
    public static let standard = RibbonGlassPreferences()
    public let transparency: Double
    public let tint: Double
    public let grain: Double

    public init(transparency: Double = 0.75, tint: Double = 0.5, grain: Double = 0) {
        self.transparency = Self.normalized(transparency, fallback: 0.75)
        self.tint = Self.normalized(tint, fallback: 0.5)
        self.grain = Self.normalized(grain, fallback: 0)
    }

    private enum CodingKeys: String, CodingKey { case transparency, tint, grain }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(transparency: try values.decodeIfPresent(Double.self, forKey: .transparency) ?? 0.75,
                  tint: try values.decodeIfPresent(Double.self, forKey: .tint) ?? 0.5,
                  grain: try values.decodeIfPresent(Double.self, forKey: .grain) ?? 0)
    }

    private static func normalized(_ value: Double, fallback: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : fallback
    }
}
