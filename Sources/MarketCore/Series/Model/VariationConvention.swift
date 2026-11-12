// Convention de calcul des variations : en points, en pourcentage relatif ou indisponible.
import Foundation

public enum VariationConvention: String, Codable, Sendable { case points, relativePercent, unavailable }
