// Règle de seuil persistée : série ciblée, sens, valeur et dernier contrôle.
import Foundation

public struct AlertRule: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let seriesID: String
    public let direction: AlertDirection
    public let threshold: Decimal
    public var isEnabled: Bool
    /// Missing on legacy fund rules, which keep their original relative-change semantics.
    public let condition: AlertCondition?
    public var lastEvaluatedAt: Date?

    public init(id: UUID = UUID(), seriesID: String, direction: AlertDirection, threshold: Decimal,
                isEnabled: Bool = true, condition: AlertCondition = .relativeChange, lastEvaluatedAt: Date? = nil) {
        self.id = id
        self.seriesID = seriesID
        self.direction = direction
        self.threshold = threshold
        self.isEnabled = isEnabled
        self.condition = condition
        self.lastEvaluatedAt = lastEvaluatedAt
    }

    public var effectiveCondition: AlertCondition { condition ?? .relativeChange }
    public var isValid: Bool {
        !threshold.isNaN && (effectiveCondition == .level || (threshold > 0 && threshold <= AlertThreshold.maximumRelativeChange))
    }
}
