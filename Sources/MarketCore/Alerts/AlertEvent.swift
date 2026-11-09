// Franchissement constaté, daté par l’observation qui l’a produit.
import Foundation

public struct AlertEvent: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let ruleID: UUID
    public let seriesID: String
    public let observedAt: Date
    public let changePercent: Decimal
    public let observedValue: Decimal?
    /// Multiple of the usual variation, for an unusual move.
    public let ratio: Double?

    public init(ruleID: UUID, seriesID: String, observedAt: Date, changePercent: Decimal,
                observedValue: Decimal? = nil, ratio: Double? = nil) {
        self.id = UUID()
        self.ruleID = ruleID
        self.seriesID = seriesID
        self.observedAt = observedAt
        self.changePercent = changePercent
        self.observedValue = observedValue
        self.ratio = ratio
    }
}
