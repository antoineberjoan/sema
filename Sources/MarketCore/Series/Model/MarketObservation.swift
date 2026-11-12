// Valeur publiée à une date, distincte de sa date de mise à jour.
import Foundation

public struct MarketObservation: Codable, Equatable, Sendable, Identifiable {
    public var id: Date { date }
    public let date: Date
    public let value: Decimal
    public let periodEnd: Date?
    public let updatedAt: Date?
    public let status: String?

    public init(date: Date, value: Decimal, periodEnd: Date? = nil,
                updatedAt: Date? = nil, status: String? = nil) {
        self.date = date
        self.value = value
        self.periodEnd = periodEnd
        self.updatedAt = updatedAt
        self.status = status
    }
}
