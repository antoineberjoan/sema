// Compare deux publications consécutives et produit au plus un événement par observation.
import Foundation

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
            guard series.canAlert, series.category != .funds, series.observations.count > 1 else { return nil }
            return crossing(rule, previous: series.observations[series.observations.count - 2],
                            latest: latest)
        }
        guard series.category == .funds, let change = series.dailyChange else { return nil }
        let exceeded = rule.direction == .fall ? change < -rule.threshold : change > rule.threshold
        guard exceeded else { return nil }
        return AlertEvent(ruleID: rule.id, seriesID: series.id, observedAt: latest.date,
                          changePercent: change)
    }

    /// Checks every new pair since the persisted checkpoint, including intermediate crossings.
    /// Revisions of an already processed date do not emit a second notification.
    public static func newEvents(_ rule: AlertRule, series: MarketSeries) -> [AlertEvent] {
        guard rule.isEnabled, rule.isValid, rule.effectiveCondition == .level,
              rule.seriesID == series.id, series.canAlert, series.category != .funds,
              let checkpoint = rule.lastEvaluatedAt else { return [] }
        return zip(series.observations, series.observations.dropFirst()).compactMap { previous, latest in
            guard latest.date > checkpoint else { return nil }
            return crossing(rule, previous: previous, latest: latest)
        }
    }

    private static func crossing(_ rule: AlertRule, previous: MarketObservation,
                                 latest: MarketObservation) -> AlertEvent? {
        let crossed = rule.direction == .rise
            ? previous.value <= rule.threshold && latest.value > rule.threshold
            : previous.value >= rule.threshold && latest.value < rule.threshold
        guard crossed else { return nil }
        return AlertEvent(ruleID: rule.id, seriesID: rule.seriesID, observedAt: latest.date,
                          changePercent: 0, observedValue: latest.value)
    }
}
