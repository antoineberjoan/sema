import Foundation

public struct AppPreferences: Codable, Equatable, Sendable {
    public var schemaVersion = 1
    public var favoriteIDs: Set<String>
    public var alerts: [AlertRule]
    public var notificationsEnabled: Bool
    public var themeID: String?

    public init(
        favoriteIDs: Set<String> = ["fr10", "eurusd", "livreta"],
        alerts: [AlertRule] = [], notificationsEnabled: Bool = false, themeID: String? = "teal"
    ) {
        self.favoriteIDs = favoriteIDs
        self.alerts = alerts
        self.notificationsEnabled = notificationsEnabled
        self.themeID = themeID
    }
}

public struct PreferencesStore: Sendable {
    public enum StoreError: Error, LocalizedError {
        case unsupportedVersion(Int)
        public var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let version): "Version de réglages non prise en charge : \(version)."
            }
        }
    }

    public let fileURL: URL
    public init(fileURL: URL) { self.fileURL = fileURL }

    public func load() throws -> AppPreferences {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return AppPreferences() }
        let value = try JSONDecoder().decode(AppPreferences.self, from: Data(contentsOf: fileURL))
        guard value.schemaVersion == 1 else { throw StoreError.unsupportedVersion(value.schemaVersion) }
        return value
    }

    public func save(_ preferences: AppPreferences) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(preferences).write(to: fileURL, options: .atomic)
    }
}
