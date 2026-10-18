// Lit et écrit atomiquement les préférences sans remplacer un document illisible.
import Foundation

public struct PreferencesStore: Sendable {
    public enum StoreError: Error, LocalizedError {
        case unsupportedVersion(Int)
        public var errorDescription: String? {
            switch self { case .unsupportedVersion(let version): "Version de réglages non prise en charge : \(version)." }
        }
    }
    public let fileURL: URL
    public init(fileURL: URL) { self.fileURL = fileURL }

    public func load() throws -> AppPreferences {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return try AppPreferences().migrated() }
        let data = try Data(contentsOf: fileURL)
        let previous = try JSONDecoder().decode(AppPreferences.self, from: data)
        let value = try previous.migrated()
        if previous.schemaVersion == 1 {
            // Keep the source document beside the atomically written migration.
            let backup = fileURL.appendingPathExtension("v1-backup")
            if !FileManager.default.fileExists(atPath: backup.path) { try data.write(to: backup, options: .atomic) }
            try save(value)
        }
        return value
    }

    public func save(_ preferences: AppPreferences) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(preferences).write(to: fileURL, options: .atomic)
    }
}
