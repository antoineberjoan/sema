// Compare deux publications consécutives et produit au plus un événement par observation.
import Foundation

public enum AlertEvaluator {
    /// Évalue deux publications consécutives pour la série exacte.
    /// Un seuil est strictement dépassé, pas seulement atteint.
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

    /// Vérifie chaque nouvelle paire depuis le point de contrôle enregistré, franchissements intermédiaires compris.
    /// Les révisions d’une date déjà traitée n’émettent pas de seconde notification.
    public static func newEvents(_ rule: AlertRule, series: MarketSeries,
                                 sensitivity: MoveSensitivity = .standard) -> [AlertEvent] {
        guard rule.isEnabled, rule.isValid, rule.effectiveCondition != .relativeChange,
              rule.seriesID == series.id, series.canAlert, series.category != .funds,
              let checkpoint = rule.lastEvaluatedAt else { return [] }
        if rule.effectiveCondition == .unusualMove {
            return series.observations.indices.compactMap { index in
                guard series.observations[index].date > checkpoint,
                      let move = UnusualMove(series: series, at: index),
                      move.ratio >= sensitivity.multiplier else { return nil }
                return AlertEvent(ruleID: rule.id, seriesID: series.id, observedAt: move.observation.date,
                                  changePercent: move.change, observedValue: move.observation.value, ratio: move.ratio)
            }
        }
        return zip(series.observations, series.observations.dropFirst()).compactMap { previous, latest in
            guard latest.date > checkpoint else { return nil }
            return crossing(rule, previous: previous, latest: latest)
        }
    }

    /// Vérifie toutes les règles actives sur les séries reçues. Une règle à réinitialiser reprend à la dernière observation sans émettre d'événement.
    public static func check(rules: [AlertRule], baselineIDs: Set<UUID>?, series values: [MarketSeries],
                             sensitivity: MoveSensitivity, isSourceEnabled: (String) -> Bool) -> AlertCheck {
        var result = AlertCheck(rules: rules, baselineIDs: baselineIDs, events: [], hasAdvanced: false)
        for index in result.rules.indices {
            let rule = result.rules[index]
            guard rule.isEnabled, rule.effectiveCondition != .relativeChange,
                  isSourceEnabled(rule.seriesID),
                  let item = values.first(where: { $0.id == rule.seriesID }), item.canAlert,
                  let latest = item.latest else { continue }
            if result.baselineIDs?.contains(rule.id) == true {
                result.rules[index].lastEvaluatedAt = max(latest.date, rule.lastEvaluatedAt ?? latest.date)
                result.baselineIDs?.remove(rule.id); result.hasAdvanced = true
                continue
            }
            guard rule.lastEvaluatedAt.map({ latest.date > $0 }) ?? true else { continue }
            result.events += newEvents(rule, series: item, sensitivity: sensitivity)
            result.rules[index].lastEvaluatedAt = latest.date; result.hasAdvanced = true
        }
        return result
    }

    /// Deux observations de part et d'autre du seuil, pour tester la notification d'une règle sans toucher aux données réelles.
    public static func testSample(for rule: AlertRule, series item: MarketSeries, now: Date) -> MarketSeries {
        let step: Decimal = 0.1
        let sign: Decimal = rule.direction == .fall ? -1 : 1
        return item.replacing(observations: [
            .init(date: now.addingTimeInterval(-60), value: rule.threshold - sign * step),
            .init(date: now, value: rule.threshold + sign * step)
        ])
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
