import Foundation
import MarketCore

struct LocalStorage {
    let directory: URL

    static func applicationDefault() -> LocalStorage {
        if let path = Bundle.main.object(forInfoDictionaryKey: "SemaDevelopmentDataDirectory") as? String {
            return LocalStorage(directory: URL(fileURLWithPath: path, isDirectory: true))
        }
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return LocalStorage(directory: root.appendingPathComponent("Sema", isDirectory: true))
    }

    var preferences: PreferencesStore { PreferencesStore(fileURL: directory.appendingPathComponent("preferences.json")) }

    func cachedRates() throws -> [MarketSeries] {
        let url = directory.appendingPathComponent("ecb-cache.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([MarketSeries].self, from: Data(contentsOf: url))
    }

    func cacheRates(_ rates: [MarketSeries]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(rates).write(to: directory.appendingPathComponent("ecb-cache.json"), options: .atomic)
    }

    func cachedWebstat() throws -> [MarketSeries] {
        let url = directory.appendingPathComponent("webstat-cache.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        if let cache = try? JSONDecoder().decode(WebstatCache.self, from: data) {
            guard cache.schemaVersion == 2 else { throw PreferencesStore.StoreError.unsupportedVersion(cache.schemaVersion) }
            return cache.series
        }
        let legacy = try JSONDecoder().decode([MarketSeries].self, from: data)
        let migrated = legacy.map { $0.withID(WebstatClient.canonicalID($0.id)) }
        let backup = url.appendingPathExtension("v1-backup")
        if !FileManager.default.fileExists(atPath: backup.path) { try data.write(to: backup, options: .atomic) }
        try cacheWebstat(migrated)
        return migrated
    }

    func cacheWebstat(_ series: [MarketSeries]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(WebstatCache(series: series)).write(to: directory.appendingPathComponent("webstat-cache.json"), options: .atomic)
    }
    func cachedCatalogue() throws -> WebstatCatalogueCache? {
        let url = directory.appendingPathComponent("webstat-catalogue.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(WebstatCatalogueCache.self, from: Data(contentsOf: url))
    }
    func cacheCatalogue(_ cache: WebstatCatalogueCache) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(cache).write(to: directory.appendingPathComponent("webstat-catalogue.json"), options: .atomic)
    }
    func cachedStatisticalCatalogues() throws -> [String: [StatisticalDataset]] {
        let url = directory.appendingPathComponent("statistical-catalogues.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return [:] }
        let cache = try JSONDecoder().decode(StatisticalCatalogueCache.self, from: Data(contentsOf: url))
        guard cache.schemaVersion == 1 else { throw PreferencesStore.StoreError.unsupportedVersion(cache.schemaVersion) }
        return cache.datasets
    }
    func cacheStatisticalCatalogues(_ datasets: [String: [StatisticalDataset]]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(StatisticalCatalogueCache(datasets: datasets))
            .write(to: directory.appendingPathComponent("statistical-catalogues.json"), options: .atomic)
    }
}

private struct WebstatCache: Codable {
    var schemaVersion = 2
    let series: [MarketSeries]
}
struct WebstatCatalogueCache: Codable {
    var schemaVersion = 1
    let datasets: [WebstatDataset]
    let labels: [String: [String: String]]
}
private struct StatisticalCatalogueCache: Codable {
    var schemaVersion = 1
    let datasets: [String: [StatisticalDataset]]
}
