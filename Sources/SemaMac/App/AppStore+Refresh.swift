// Sélectionne les séries suivies et connectées admissibles à l’actualisation automatique.
import MarketCore

extension AppStore {
    /// Une série surveillée pour les mouvements inhabituels est aussi vérifiée après chaque clôture du marché.
    func followsCloses(_ series: MarketSeries) -> Bool {
        preferences.alerts.contains { $0.seriesID == series.id && $0.isEnabled && $0.effectiveCondition == .unusualMove }
    }

    var automaticRefreshSeries: [MarketSeries] {
        guard !isOnboardingPresented else { return [] }
        return followedSeries.filter {
            RefreshPolicy.isAutomaticallyRefreshable($0, isSourceEnabled: isSourceEnabled(for: $0.id),
                connectedProviders: connectedMarkets, hasWebstatKey: hasWebstatKey)
        }
    }
}
