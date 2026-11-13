// Cherche dans le catalogue Webstat et prépare l’aperçu d’une série avant son ajout.
import Foundation
import MarketCore

extension AppStore {
    /// Une pause après la dernière frappe évite une requête par lettre.
    static let searchDelay: Duration = .milliseconds(250)
    var canLoadMoreCatalogue: Bool { hasMoreCatalogue && !isSearchingCatalogue }

    var isPreviewRefreshRequired: Bool {
        if let value = previewSeries, let next = value.statisticalDescriptor,
           let previous = followedSeries.first(where: { $0.id == value.id })?.statisticalDescriptor {
            return !previous.usesSameMeasurement(as: next)
        }
        guard let descriptor = previewDescriptor,
              let previous = followedSeries.first(where: { $0.id == descriptor.key })?.descriptor else { return false }
        return !previous.usesSameMeasurement(as: descriptor)
    }

    func searchCatalogue(loadMore: Bool = false) {
        searchTask?.cancel()
        let generation = UUID(); searchGeneration = generation
        var search = catalogueSearch
        if let dataset = catalogueDatasets.first(where: { $0.id == search.datasetID }) { search.areaField = dataset.areaField ?? "ref_area" }
        let offset = loadMore ? catalogueResults.count : 0
        if summaryExportSearch != search { summaryExportSearch = nil; summaryExport = [] }
        if !loadMore { catalogueResults = []; catalogueTotal = 0; hasMoreCatalogue = false }
        catalogueError = nil
        guard hasWebstatKey, isSourceEnabled("webstat") else { isSearchingCatalogue = false; return }
        isSearchingCatalogue = true
        searchTask = Task {
            do {
                if !loadMore { try await Task.sleep(for: Self.searchDelay) }
                let key = try await requiredKey()
                try Task.checkCancellation()
                guard generation == searchGeneration else { return }
                if catalogueDatasets.isEmpty { catalogueDatasets = try await WebstatClient().datasets(apiKey: key) }
                let areaList = catalogueDatasets.first(where: { $0.id == search.datasetID })?.areaCodelist ?? "CL_AREA"
                let missing = ["CL_UNIT", "CL_UNIT_MULT", "CL_FREQ", "CL_ORGANISATION", areaList].filter { catalogueLabels[$0] == nil }
                if !missing.isEmpty {
                    let labels = try await WebstatClient().codeLabels(apiKey: key, ids: missing)
                    try Task.checkCancellation()
                    guard generation == searchGeneration else { return }
                    catalogueLabels.merge(labels, uniquingKeysWith: { _, replacement in replacement })
                    try? storage.cacheCatalogue(.init(datasets: catalogueDatasets, labels: catalogueLabels))
                }
                let page: WebstatPage<WebstatSeriesDescriptor>
                if WebstatClient.usesSummaryExport(forOffset: offset) {
                    if summaryExportSearch != search {
                        let summaries = try await WebstatClient().exportSummaries(apiKey: key, search: search)
                        try Task.checkCancellation()
                        guard generation == searchGeneration else { return }
                        summaryExport = summaries; summaryExportSearch = search
                    }
                    page = .slice(of: summaryExport, offset: offset, size: WebstatClient.pageSize)
                    catalogueTotal = page.total
                } else {
                    page = try await WebstatClient().search(apiKey: key, search: search, offset: offset)
                    try Task.checkCancellation()
                    guard generation == searchGeneration else { return }
                    if !loadMore { catalogueTotal = page.total }
                }
                try Task.checkCancellation()
                guard generation == searchGeneration else { return }
                let resolvedItems = page.items.map { resolvedWithCachedLabels($0) }
                if loadMore {
                    let known = Set(catalogueResults.map(\.key)); catalogueResults += resolvedItems.filter { !known.contains($0.key) }
                } else {
                    catalogueResults = search.query.isEmpty ? WebstatStarter.placingFirst(resolvedItems) : resolvedItems
                }
                hasMoreCatalogue = page.hasMore
                isSearchingCatalogue = false
            } catch is CancellationError { }
            catch {
                guard generation == searchGeneration else { return }
                catalogueError = error.localizedDescription; isSearchingCatalogue = false
            }
        }
    }

    func cancelCatalogueSearch() { searchTask?.cancel(); searchGeneration = UUID(); isSearchingCatalogue = false }

    func openPreview(_ descriptor: WebstatSeriesDescriptor) {
        guard isSourceEnabled("webstat") else { return }
        previewSourceID = "webstat"
        statisticalPreviewRequest = nil
        previewTask?.cancel(); previewDescriptor = descriptor
        previewSeries = series.first { $0.id == descriptor.key }
        previewError = nil; isLoadingPreview = true
        previewTask = Task {
            do {
                let key = try await requiredKey()
                let official = try await WebstatClient().descriptor(apiKey: key, key: descriptor.key)
                let resolved = await resolve(official, apiKey: key)
                try Task.checkCancellation()
                guard previewDescriptor?.key == descriptor.key else { return }
                previewDescriptor = resolved
                let value = try await fetchRecent(descriptor: resolved, apiKey: key)
                try Task.checkCancellation()
                guard previewDescriptor?.key == descriptor.key else { return }
                previewDescriptor = resolved
                let compatible = previewSeries?.descriptor?.usesSameMeasurement(as: resolved) ?? true
                previewSeries = value.continuing(previewSeries, sameMeasurement: compatible)
                if isPreviewRefreshRequired {
                    previewError = "La source a changé d’unité, d’échelle ou de base. Cet aperçu utilise les nouvelles valeurs ; actualisez vos repères avant de l’ouvrir."
                }
                isLoadingPreview = false
            } catch is CancellationError { }
            catch {
                guard previewDescriptor?.key == descriptor.key else { return }
                previewError = error.localizedDescription; isLoadingPreview = false
            }
        }
    }

    func openStatisticalPreview(dataset: StatisticalDataset, structure: StatisticalStructure, key: String) {
        guard isSourceEnabled(dataset.source.rawValue) else { return }
        closePreview()
        previewSourceID = dataset.source.rawValue
        let requestID = UUID().uuidString; statisticalPreviewRequest = requestID; isLoadingPreview = true
        previewTask = Task {
            do {
                let value = try await statisticalConnectors().fetch(dataset: dataset, structure: structure, key: key)
                try Task.checkCancellation()
                guard statisticalPreviewRequest == requestID else { return }
                if let held = series.first(where: { $0.id == value.id }),
                   let previous = held.statisticalDescriptor, let next = value.statisticalDescriptor,
                   previous.usesSameMeasurement(as: next) {
                    previewSeries = value.continuing(held)
                } else { previewSeries = value }
                if isPreviewRefreshRequired { previewError = "L’unité, l’échelle ou la base a changé. Actualisez vos repères et vérifiez les seuils avant de l’ouvrir." }
                isLoadingPreview = false
            } catch is CancellationError { }
            catch {
                guard statisticalPreviewRequest == requestID else { return }
                previewError = error.localizedDescription; isLoadingPreview = false
            }
        }
    }

    func closePreview() {
        previewTask?.cancel()
        previewSourceID = nil
        if historyLoadingID == previewDescriptor?.key || historyLoadingID == previewSeries?.id { cancelHistory() }
        previewDescriptor = nil; statisticalPreviewRequest = nil; previewSeries = nil; previewError = nil; isLoadingPreview = false
    }

    private func resolvedWithCachedLabels(_ descriptor: WebstatSeriesDescriptor) -> WebstatSeriesDescriptor {
        descriptor.resolving(codeLabels: catalogueLabels, dataset: catalogueDatasets.first { $0.id == descriptor.datasetID })
    }

    func resolve(_ descriptor: WebstatSeriesDescriptor, apiKey: String) async -> WebstatSeriesDescriptor {
        let dataset = catalogueDatasets.first { $0.id == descriptor.datasetID }
        let lists = Array((dataset?.dimensionCodelists ?? [:]).values) + Array((dataset?.attributeCodelists ?? [:]).values)
        let ids = Array(Set(lists + ["CL_UNIT", "CL_UNIT_MULT", "CL_FREQ", "CL_ORGANISATION", "CL_AREA"])).filter { catalogueLabels[$0] == nil }
        if !ids.isEmpty, let labels = try? await WebstatClient().codeLabels(apiKey: apiKey, ids: ids) {
            catalogueLabels.merge(labels, uniquingKeysWith: { _, replacement in replacement })
            try? storage.cacheCatalogue(.init(datasets: catalogueDatasets, labels: catalogueLabels))
        }
        return resolvedWithCachedLabels(descriptor)
    }
}
