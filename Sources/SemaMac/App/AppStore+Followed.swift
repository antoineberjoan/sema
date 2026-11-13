// Suit, retire, réordonne et épingle les repères de la sélection personnelle.
import Foundation
import MarketCore

extension AppStore {
    func followedMatch(for value: MarketSeries) -> MarketSeries? {
        followedSeries.first { SeriesEquivalence.matches($0, value) }
    }

    func isFollowing(_ id: String) -> Bool { preferences.followedSeriesIDs.contains(id) }

    func isFavorite(_ id: String) -> Bool {
        guard let item = series.first(where: { $0.id == id }) else { return preferences.favoriteIDs.contains(id) }
        return storedFollowedSeries.contains { preferences.favoriteIDs.contains($0.id) && SeriesEquivalence.matches($0, item) }
    }

    func toggleFavorite(_ id: String) {
        guard isFollowing(id) else { return }
        let equivalentIDs = FollowedOrder.equivalentIDs(of: series.first { $0.id == id }, among: storedFollowedSeries)
        let wasFavorite = isFavorite(id)
        mutatePreferences { value in
            if wasFavorite { value.favoriteIDs.subtract(equivalentIDs) } else { value.favoriteIDs.insert(id) }
        }
    }

    func saveFollowed(_ value: MarketSeries) throws -> Bool {
        let source = value.marketInstrument?.provider.rawValue ?? value.statisticalDescriptor?.dataset.source.rawValue ?? "webstat"
        guard isSourceEnabled(source) else { return false }
        if let existing = followedMatch(for: value) {
            status = "Ce repère est déjà suivi via \(existing.originBadge)."
            return true
        }
        // Écrit le cache avant les préférences, pour chaque fournisseur.
        let merged = series.filter { $0.id != value.id } + [value]
        try storage.cacheWebstat(merged)
        guard mutatePreferences({ $0.followedSeriesIDs.append(value.id) }) else { return false }
        merge([value])
        hasLoadedWebstat = series.contains { $0.sourceURL?.host == "webstat.banque-france.fr" }
        status = "Repère ajouté · \(value.source)."
        if selectedSeries == nil { show(value) }
        return true
    }

    func moveFollowed(_ id: String, by offset: Int) {
        if let ordered = FollowedOrder.moving(followedSeries, id: id, by: offset) { reorderFollowed(ordered) }
    }

    func moveFollowed(from offsets: IndexSet, to destination: Int) {
        if let ordered = FollowedOrder.moving(followedSeries, from: offsets, to: destination) { reorderFollowed(ordered) }
    }

    private func reorderFollowed(_ ordered: [MarketSeries]) {
        let ids = FollowedOrder.ids(ordered: ordered, stored: storedFollowedSeries, followedIDs: preferences.followedSeriesIDs)
        mutatePreferences { $0.followedSeriesIDs = ids }
    }

    func prepareAlert(for item: MarketSeries) {
        show(item); closePreview()
        if isSearchPresented { isAlertOpenPending = true; isSearchPresented = false }
        else { isAlertSheetPresented = true }
    }

    func finishSearch() {
        if isAlertOpenPending { isAlertOpenPending = false; isAlertSheetPresented = true }
    }
}
