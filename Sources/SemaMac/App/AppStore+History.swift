// Charge l’historique complet d’une série par tranches annulables.
import Foundation
import MarketCore

extension AppStore {
    func canLoadFullHistory(_ item: MarketSeries) -> Bool {
        !item.isDemo && isSourceEnabled(for: item.id) && (item.statisticalDescriptor != nil || (hasWebstatKey && item.descriptor?.firstPeriod != nil))
    }

    func loadAllHistory(_ item: MarketSeries, reload: Bool = false) {
        guard isSourceEnabled(for: item.id) else { return }
        if let descriptor = item.statisticalDescriptor {
            loadStatisticalHistory(item, descriptor: descriptor); return
        }
        guard !item.isDemo, let descriptor = item.descriptor else { return }
        historyTask?.cancel(); let generation = UUID(); historyGeneration = generation
        historyLoadingID = item.id; historyProgress = "Chargement des périodes anciennes…"
        historyTask = Task {
            defer { if historyGeneration == generation { historyLoadingID = nil; historyProgress = nil } }
            do {
                let key = try await requiredKey()
                let current = try await WebstatClient().descriptor(apiKey: key, key: descriptor.key)
                guard descriptor.usesSameMeasurement(as: current) else { throw WebstatClient.ClientError.metadataChanged }
                let descriptor = current.resolving(labels: descriptor.labels)
                guard let first = descriptor.firstObservationStart else { throw WebstatClient.ClientError.incompleteData }
                var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
                var end = reload ? min(descriptor.lastPeriod ?? .now, .now) : item.observations.first?.date ?? .now
                var points = reload ? [] : item.observations
                while end >= first {
                    try Task.checkCancellation()
                    let start = max(first, calendar.date(byAdding: .year, value: -HistoryPeriod.recentYears, to: end)!)
                    let older = try await WebstatClient().observations(apiKey: key, descriptor: descriptor, start: start, end: end)
                    points = older + points
                    try Task.checkCancellation()
                    let complete = start <= first
                    let value = descriptor.series(observations: points, syncedAt: .now, completeHistory: complete)
                    if isFollowing(item.id) {
                        merge([value]); try storage.cacheWebstat(series.filter { !$0.isDemo })
                    }
                    if previewDescriptor?.key == item.id { previewSeries = value }
                    historyProgress = "Historique reçu depuis \(MarketFormat.date(value.observations.first?.date))"
                    if complete { break }
                    end = start.addingTimeInterval(-.day)
                }
            } catch is CancellationError { }
            catch { seriesErrors[item.id] = error.localizedDescription; if previewDescriptor?.key == item.id { previewError = error.localizedDescription } }
        }
    }

    func cancelHistory() { historyTask?.cancel(); historyGeneration = UUID(); historyLoadingID = nil; historyProgress = nil }

    private func loadStatisticalHistory(_ item: MarketSeries, descriptor: StatisticalSeriesDescriptor) {
        historyTask?.cancel(); let generation = UUID(); historyGeneration = generation
        historyLoadingID = item.id; historyProgress = "Chargement de l’historique publié…"
        historyTask = Task {
            defer { if historyGeneration == generation { historyLoadingID = nil; historyProgress = nil } }
            do {
                let value = try await StatisticalClient().fetch(descriptor, fullHistory: true)
                try Task.checkCancellation()
                guard historyGeneration == generation else { return }
                if isFollowing(item.id) {
                    try storage.cacheWebstat((series.filter { $0.id != item.id } + [value]).filter { !$0.isDemo })
                    merge([value])
                }
                if previewSeries?.id == item.id { previewSeries = value }
            } catch is CancellationError { }
            catch { seriesErrors[item.id] = error.localizedDescription; if previewSeries?.id == item.id { previewError = error.localizedDescription } }
        }
    }
}
