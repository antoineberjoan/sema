// Brief du matin : mouvements inhabituels de la dernière séance, seuils proches, agenda du jour et communiqués récents.
import Foundation

public struct MorningBrief: Equatable, Sendable {
    /// Un seuil est proche à 2 % de sa valeur, ou 0,10 point pour les taux.
    public static let nearPercent: Decimal = 2
    public static let nearPoints: Decimal = 0.1
    /// Les séances plus anciennes ne sont plus « la dernière séance » (un long week-end passe).
    public static let recentDays = 4

    public struct NearThreshold: Equatable, Identifiable, Sendable {
        public let rule: AlertRule
        public let series: MarketSeries
        /// Écart restant, en points pour les taux et en pourcent du seuil sinon.
        public let gap: Decimal
        public var id: UUID { rule.id }
    }

    public let moves: [PeerMove]
    public let nearThresholds: [NearThreshold]
    public var agenda: [EconomicRelease] = []
    public var pressReleases: [PressRelease] = []

    public var isQuiet: Bool { moves.isEmpty && nearThresholds.isEmpty }

    /// Mouvements inhabituels à la sensibilité choisie et seuils de niveau pas encore franchis mais proches.
    public init(series: [MarketSeries], alerts: [AlertRule], sensitivity: MoveSensitivity, now: Date) {
        let oldest = now.addingTimeInterval(-Double(Self.recentDays) * .day)
        let recent = series.filter { ($0.latest?.date ?? .distantPast) >= oldest }
        moves = recent.compactMap { item -> PeerMove? in
            guard let move = UnusualMove(series: item), move.ratio >= sensitivity.multiplier else { return nil }
            return PeerMove(series: item, change: move.change, ratio: move.ratio)
        }.sorted { ($0.ratio ?? 0) > ($1.ratio ?? 0) }
        nearThresholds = alerts.compactMap { rule -> NearThreshold? in
            guard rule.isEnabled, rule.effectiveCondition == .level,
                  let item = recent.first(where: { $0.id == rule.seriesID }), let value = item.latest?.value else { return nil }
            let remaining = rule.direction == .rise ? rule.threshold - value : value - rule.threshold
            guard remaining > 0 else { return nil }
            if item.unit == .percent { return remaining <= Self.nearPoints ? NearThreshold(rule: rule, series: item, gap: remaining) : nil }
            guard rule.threshold != 0 else { return nil }
            let gap = remaining / abs(rule.threshold) * 100
            return gap <= Self.nearPercent ? NearThreshold(rule: rule, series: item, gap: gap) : nil
        }.sorted { $0.gap < $1.gap }
    }
}
