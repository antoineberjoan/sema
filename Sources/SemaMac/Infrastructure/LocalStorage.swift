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
}
