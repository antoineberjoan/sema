// Vérifie que le dépôt de préférences écrit ce qu'il relit et refuse un fichier illisible ou d'une version future.
import Foundation
import Testing
@testable import MarketCore

struct PreferencesRepositoryTests {
    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("sema-test-" + UUID().uuidString)
    }

    @Test func preferencesPersistFavoritesAndDecimalAlertThreshold() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PreferencesRepository(fileURL: directory.appendingPathComponent("preferences.json"))
        var preferences = AppPreferences(favoriteIDs: ["series-a", "eurusd"])
        preferences.alerts = [AlertRule(seriesID: "series-a", direction: .fall, threshold: Decimal(string: "2.5")!)]
        try store.save(preferences)
        #expect(try store.load() == preferences)
    }

    @Test func unreadableOrFuturePreferencesAreNotSilentlyAccepted() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("preferences.json")
        let store = PreferencesRepository(fileURL: file)
        try Data("broken".utf8).write(to: file)
        #expect(throws: (any Error).self) { _ = try store.load() }
        #expect(try String(contentsOf: file, encoding: .utf8) == "broken")
        var future = AppPreferences()
        future.schemaVersion = 99
        try JSONEncoder().encode(future).write(to: file)
        #expect(throws: (any Error).self) { _ = try store.load() }
    }
}
