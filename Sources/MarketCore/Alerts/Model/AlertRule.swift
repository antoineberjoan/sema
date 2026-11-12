// Règle d’alerte persistée : série ciblée, condition, sens, valeur et dernier contrôle.
import Foundation

public struct AlertRule: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let seriesID: String
    public let direction: AlertDirection
    public let threshold: Decimal
    public var isEnabled: Bool
    /// Absente d’une règle de fonds écrite en schéma 1 : elle garde la variation relative.
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
        switch effectiveCondition {
        case .level, .unusualMove: !threshold.isNaN
        case .relativeChange: !threshold.isNaN && threshold > 0 && threshold <= AlertThreshold.maximumRelativeChange
        }
    }

    /// An unusual-move watch covers both directions and follows the global sensitivity, so its direction
    /// and threshold are fixed and never read.
    public static func unusualMove(seriesID: String, lastEvaluatedAt: Date?) -> AlertRule {
        AlertRule(seriesID: seriesID, direction: .rise, threshold: 0, condition: .unusualMove, lastEvaluatedAt: lastEvaluatedAt)
    }
}
