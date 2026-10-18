// Sélectionne les séries suivies et connectées admissibles à l’actualisation automatique.
import MarketCore

extension AppStore {
    var automaticRefreshSeries: [MarketSeries] {
        guard !isOnboardingPresented else { return [] }
        return followedSeries.filter {
            isSourceEnabled(for: $0.id) && ($0.marketInstrument.map { connectedMarkets.contains($0.provider) }
                ?? ($0.statisticalDescriptor != nil || hasWebstatKey))
        }
    }
}
