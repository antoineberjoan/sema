// Vérifie la conservation du mode d’apparence et le repli des préférences anciennes.
import Foundation
import Testing
@testable import MarketCore

struct AppearancePreferencesTests {
    @Test func existingPreferencesKeepTheirPaletteAndSelection() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-appearance-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("preferences.json")
        let previous = Data("""
        {"schemaVersion":2,"favoriteIDs":["eurusd"],"followedSeriesIDs":["eurusd"],"alerts":[],"notificationsEnabled":false,"themeID":"polar"}
        """.utf8)
        try previous.write(to: file)
        let value = try PreferencesStore(fileURL: file).load()
        #expect(value.appearanceID == nil)
        #expect(value.themeID == "polar")
        #expect(value.followedSeriesIDs == [WebstatClient.canonicalID("eurusd")])
        #expect(value.favoriteIDs == [WebstatClient.canonicalID("eurusd")])
        #expect(try Data(contentsOf: file) == previous)
    }

    @Test func appearanceAndPalettePersistIndependently() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-appearance-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PreferencesStore(fileURL: directory.appendingPathComponent("preferences.json"))
        try store.save(AppPreferences(themeID: "polar", appearanceID: "dark"))
        var value = try store.load()
        #expect(value.appearanceID == "dark")
        value.themeID = "mint"
        try store.save(value)
        value = try store.load()
        #expect(value.themeID == "mint")
        #expect(value.appearanceID == "dark")
        value.appearanceID = "light"
        try store.save(value)
        value = try store.load()
        #expect(value.appearanceID == "light")
        #expect(value.themeID == "mint")
    }
}
