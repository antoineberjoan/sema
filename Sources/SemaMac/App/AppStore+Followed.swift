// Suit, retire, réordonne et épingle les repères de la sélection personnelle.
import Foundation
import MarketCore

extension AppStore {
    func followedMatch(for value: MarketSeries) -> MarketSeries? {
        followedSeries.first { SeriesEquivalence.matches($0, value) }
    }

    func isFollowing(_ id: String) -> Bool { preferences.followedSeriesIDs.contains(WebstatClient.canonicalID(id)) }

    func isFavorite(_ id: String) -> Bool {
        guard let item = series.first(where: { $0.id == id }) else { return preferences.favoriteIDs.contains(id) }
        return storedFollowedSeries.contains { preferences.favoriteIDs.contains($0.id) && SeriesEquivalence.matches($0, item) }
    }

    func toggleFavorite(_ id: String) {
        guard isFollowing(id) else { return }
        let equivalentIDs = Set(storedFollowedSeries.filter { candidate in
            series.first(where: { $0.id == id }).map { SeriesEquivalence.matches($0, candidate) } ?? false
        }.map(\.id))
        let wasFavorite = isFavorite(id)
        mutatePreferences { value in
            if wasFavorite { value.favoriteIDs.subtract(equivalentIDs) } else { value.favoriteIDs.insert(id) }
        }
    }

    func saveFollowed(_ value: MarketSeries) throws -> Bool {
        let source = value.statisticalDescriptor?.dataset.source.rawValue ?? "webstat"
        guard isSourceEnabled(source) else { return false }
        if let existing = followedMatch(for: value) {
            status = "Ce repère est déjà suivi via \(existing.originBadge)."
            return true
        }
        // Persist the cache before preferences, for every provider.
        let merged = series.filter { $0.id != value.id } + [value]
        try storage.cacheWebstat(merged.filter { !$0.isDemo })
        guard mutatePreferences({ $0.followedSeriesIDs.append(value.id) }) else { return false }
        merge([value])
        hasLoadedWebstat = series.contains { !$0.isDemo && $0.sourceURL?.host == "webstat.banque-france.fr" }
        status = "Repère ajouté · \(value.source)."
        if selectedSeries == nil { show(value) }
        return true
    }

    func moveFollowed(_ id: String, by offset: Int) {
        var ordered = followedSeries
        guard let index = ordered.firstIndex(where: { $0.id == id }) else { return }
        let target = index + offset
        guard ordered.indices.contains(target) else { return }
        ordered.swapAt(index, target); reorderFollowed(ordered)
    }

    func moveFollowed(from offsets: IndexSet, to destination: Int) {
        var ordered = followedSeries
        guard offsets.allSatisfy({ ordered.indices.contains($0) }) else { return }
        let moved = offsets.sorted().map { ordered[$0] }
        for index in offsets.sorted(by: >) { ordered.remove(at: index) }
        let target = destination - offsets.filter { $0 < destination }.count
        ordered.insert(contentsOf: moved, at: min(max(0, target), ordered.count)); reorderFollowed(ordered)
    }

    private func reorderFollowed(_ ordered: [MarketSeries]) {
        let groups = ordered.flatMap { item in storedFollowedSeries.filter { SeriesEquivalence.matches(item, $0) }.map(\.id) }
        let unknown = preferences.followedSeriesIDs.filter { id in !groups.contains(id) }
        mutatePreferences { $0.followedSeriesIDs = groups + unknown }
    }

    func prepareAlert(for item: MarketSeries) {
        show(item); closePreview()
        if isSearchPresented { opensAlertAfterSearch = true; isSearchPresented = false }
        else { isAlertSheetPresented = true }
    }

    func finishSearch() {
        if opensAlertAfterSearch { opensAlertAfterSearch = false; isAlertSheetPresented = true }
    }
}
