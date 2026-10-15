import Foundation

public enum AlertDirection: String, Codable, CaseIterable, Sendable {
    case fall, rise
    public var title: String { self == .fall ? "Baisse" : "Hausse" }
}

public enum AlertThreshold {
    /// Accepts a French decimal comma or a decimal point, with no partial parsing.
    public static func parse(_ text: String) -> Decimal? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.range(of: "^[0-9]+([,.][0-9]{1,4})?$", options: .regularExpression) != nil,
              let value = Decimal(string: normalized.replacingOccurrences(of: ",", with: "."),
                                  locale: Locale(identifier: "en_US_POSIX")),
              value > 0, value <= 100 else { return nil }
        return value
    }
}

public struct AlertRule: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let seriesID: String
    public let direction: AlertDirection
    public let threshold: Decimal
    public var isEnabled: Bool

    public init(id: UUID = UUID(), seriesID: String, direction: AlertDirection, threshold: Decimal, isEnabled: Bool = true) {
        self.id = id
        self.seriesID = seriesID
        self.direction = direction
        self.threshold = threshold
        self.isEnabled = isEnabled
    }

    public var isValid: Bool { threshold > 0 && threshold <= 100 }
}

public struct AlertEvent: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let ruleID: UUID
    public let seriesID: String
    public let observedAt: Date
    public let changePercent: Decimal
    public let isDemo: Bool

    public init(ruleID: UUID, seriesID: String, observedAt: Date, changePercent: Decimal, isDemo: Bool) {
        self.id = UUID()
        self.ruleID = ruleID
        self.seriesID = seriesID
        self.observedAt = observedAt
        self.changePercent = changePercent
        self.isDemo = isDemo
    }
}

public enum AlertEvaluator {
    /// Evaluates two consecutive publications for the exact share class.
    /// A threshold is strictly exceeded, not merely reached.
    public static func evaluate(
        _ rule: AlertRule, series: MarketSeries, lastNotifiedAt: Date? = nil
    ) -> AlertEvent? {
        guard rule.isEnabled, rule.isValid, rule.seriesID == series.id,
              series.category == .funds, let latest = series.latest,
              lastNotifiedAt.map({ latest.date > $0 }) ?? true,
              let change = series.dailyChange else { return nil }
        let exceeded = rule.direction == .fall ? change < -rule.threshold : change > rule.threshold
        guard exceeded else { return nil }
        return AlertEvent(ruleID: rule.id, seriesID: series.id, observedAt: latest.date,
                          changePercent: change, isDemo: series.isDemo)
    }
}
