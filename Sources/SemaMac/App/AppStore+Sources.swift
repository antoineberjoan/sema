// Active les sources de données et charge les catalogues des producteurs statistiques.
import Foundation
import MarketCore

extension AppStore {
    func statisticalDatasets(source: StatisticalSource, reload: Bool = false) async throws -> [StatisticalDataset] {
        guard isSourceEnabled(source.rawValue) else { throw CancellationError() }
        let generation = sourceGenerations[source.rawValue]
        if !reload, let cached = statisticalCatalogues[source.rawValue] { return cached }
        let datasets = try await StatisticalClient().datasets(source: source)
        try Task.checkCancellation()
        guard isSourceEnabled(source.rawValue), generation == sourceGenerations[source.rawValue] else { throw CancellationError() }
        statisticalCatalogues[source.rawValue] = datasets
        do { try storage.cacheStatisticalCatalogues(statisticalCatalogues) }
        catch { errorMessage = "Le catalogue est chargé, mais sa sauvegarde locale a échoué." }
        return datasets
    }

    func isSourceEnabled(_ id: String) -> Bool { preferences.isSourceEnabled(id) }

    func sourceID(for id: String) -> String { statisticalDescriptors[id]?.dataset.source.rawValue ?? "webstat" }

    func isSourceEnabled(for id: String) -> Bool { isSourceEnabled(sourceID(for: id)) }

    func sourceName(_ id: String) -> String { id == "webstat" ? "Webstat" : StatisticalSource(rawValue: id)?.title ?? id }

    func sourceSeriesCount(_ id: String) -> Int { storedFollowedSeries.filter { sourceID(for: $0.id) == id }.count }

    func setSourceEnabled(_ id: String, enabled: Bool) {
        guard id == "webstat" || StatisticalSource(rawValue: id) != nil, enabled != isSourceEnabled(id) else { return }
        guard mutatePreferences({ value in
            var disabled = value.disabledSourceIDs ?? []
            if enabled { disabled.remove(id) } else { disabled.insert(id) }
            value.disabledSourceIDs = disabled
            if !enabled {
                let rules = value.alerts.filter { $0.isEnabled && sourceID(for: $0.seriesID) == id }.map(\.id)
                value.alertBaselineIDs = (value.alertBaselineIDs ?? []).union(rules)
            }
        }) else { return }
        sourceGenerations[id] = UUID()
        if !enabled {
            if id == "webstat" { cancelCatalogueSearch() }
            if previewSourceID == id { closePreview() }
            if let historyLoadingID, sourceID(for: historyLoadingID) == id { cancelHistory() }
        }
    }
}
