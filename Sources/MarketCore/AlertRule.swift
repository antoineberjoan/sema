import Foundation

public enum AlertDirection: String, Codable, CaseIterable, Sendable {
    case fall, rise
    public var title: String { self == .fall ? "Baisse" : "Hausse" }
    public var crossingTitle: String { self == .fall ? "Passe en dessous de" : "Passe au-dessus de" }
}

public enum AlertCondition: String, Codable, Sendable {
    case relativeChange, level
}

public enum AlertThreshold {
    /// A level may be zero or negative (inflation and policy rates), or exceed 100 (JPY).
    public static func parseLevel(_ text: String) -> Decimal? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.range(of: "^-?[0-9]+([,.][0-9]{1,4})?$", options: .regularExpression) != nil,
              let value = Decimal(string: normalized.replacingOccurrences(of: ",", with: "."),
                                  locale: Locale(identifier: "en_US_POSIX")), !value.isNaN else { return nil }
        return value
    }

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
        !threshold.isNaN && (effectiveCondition == .level || (threshold > 0 && threshold <= 100))
    }
}

public struct AlertEvent: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let ruleID: UUID
    public let seriesID: String
    public let observedAt: Date
    public let changePercent: Decimal
    public let isDemo: Bool
    public let observedValue: Decimal?

    public init(ruleID: UUID, seriesID: String, observedAt: Date, changePercent: Decimal, isDemo: Bool,
                observedValue: Decimal? = nil) {
        self.id = UUID()
        self.ruleID = ruleID
        self.seriesID = seriesID
        self.observedAt = observedAt
        self.changePercent = changePercent
        self.isDemo = isDemo
        self.observedValue = observedValue
    }
}

public enum AlertEvaluator {
    /// Evaluates two consecutive publications for the exact series.
    /// A threshold is strictly exceeded, not merely reached.
    public static func evaluate(
        _ rule: AlertRule, series: MarketSeries, lastNotifiedAt: Date? = nil
    ) -> AlertEvent? {
        guard rule.isEnabled, rule.isValid, rule.seriesID == series.id,
              let latest = series.latest,
              lastNotifiedAt.map({ latest.date > $0 }) ?? true else { return nil }
        if rule.effectiveCondition == .level {
            guard series.category != .funds, series.observations.count > 1 else { return nil }
            return crossing(rule, previous: series.observations[series.observations.count - 2],
                            latest: latest, isDemo: series.isDemo)
        }
        guard series.category == .funds, let change = series.dailyChange else { return nil }
        let exceeded = rule.direction == .fall ? change < -rule.threshold : change > rule.threshold
        guard exceeded else { return nil }
        return AlertEvent(ruleID: rule.id, seriesID: series.id, observedAt: latest.date,
                          changePercent: change, isDemo: series.isDemo)
    }

    /// Checks every new pair since the persisted checkpoint, including intermediate crossings.
    /// Revisions of an already processed date do not emit a second notification.
    public static func newEvents(_ rule: AlertRule, series: MarketSeries) -> [AlertEvent] {
        guard rule.isEnabled, rule.isValid, rule.effectiveCondition == .level,
              rule.seriesID == series.id, series.category != .funds, !series.isDemo,
              let checkpoint = rule.lastEvaluatedAt else { return [] }
        return zip(series.observations, series.observations.dropFirst()).compactMap { previous, latest in
            guard latest.date > checkpoint else { return nil }
            return crossing(rule, previous: previous, latest: latest, isDemo: false)
        }
    }

    private static func crossing(_ rule: AlertRule, previous: MarketObservation,
                                 latest: MarketObservation, isDemo: Bool) -> AlertEvent? {
        let crossed = rule.direction == .rise
            ? previous.value <= rule.threshold && latest.value > rule.threshold
            : previous.value >= rule.threshold && latest.value < rule.threshold
        guard crossed else { return nil }
        return AlertEvent(ruleID: rule.id, seriesID: rule.seriesID, observedAt: latest.date,
                          changePercent: 0, isDemo: isDemo, observedValue: latest.value)
    }
}
