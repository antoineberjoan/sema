// Sélectionne les séries suivies et connectées admissibles à l’actualisation automatique.
import MarketCore

extension AppStore {
    /// A series watched for unusual moves is also checked after each market close.
    func followsCloses(_ series: MarketSeries) -> Bool {
        preferences.alerts.contains { $0.seriesID == series.id && $0.isEnabled && $0.effectiveCondition == .unusualMove }
    }

    var automaticRefreshSeries: [MarketSeries] {
        guard !isOnboardingPresented else { return [] }
        return followedSeries.filter {
            isSourceEnabled(for: $0.id) && ($0.marketInstrument.map { connectedMarkets.contains($0.provider) }
                ?? ($0.statisticalDescriptor != nil || hasWebstatKey))
        }
    }
}
