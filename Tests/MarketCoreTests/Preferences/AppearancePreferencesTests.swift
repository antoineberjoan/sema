// Vérifie la conservation du mode d’apparence et le repli d’un fichier de préférences sans mode d’apparence.
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
        let value = try PreferencesRepository(fileURL: file).load()
        #expect(value.appearanceID == nil)
        #expect(value.themeID == "polar")
        #expect(value.followedSeriesIDs == [IdentifierMigration.upgrade("eurusd")])
        #expect(value.favoriteIDs == [IdentifierMigration.upgrade("eurusd")])
        #expect(try Data(contentsOf: file) == previous)
    }

    @Test func appearanceAndPalettePersistIndependently() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-appearance-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PreferencesRepository(fileURL: directory.appendingPathComponent("preferences.json"))
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

    @Test func newProfileStartsWithTheBrandPaletteAndKeepsSavedChoices() throws {
        #expect(AppPreferences().themeID == "brand")
        let saved = Data("""
        {"schemaVersion":2,"favoriteIDs":[],"followedSeriesIDs":[],"alerts":[],"notificationsEnabled":false,"themeID":"graphite"}
        """.utf8)
        #expect(try JSONDecoder().decode(AppPreferences.self, from: saved).themeID == "graphite")
    }

    @Test func sharedPeriodPersistsAndOlderFilesKeepOneYear() throws {
        let storedV1 = Data("""
        {"schemaVersion":2,"favoriteIDs":[],"followedSeriesIDs":[],"alerts":[],"notificationsEnabled":false}
        """.utf8)
        var value = try JSONDecoder().decode(AppPreferences.self, from: storedV1)
        #expect(value.periodID == nil)
        value.periodID = HistoryPeriod.threeYears.rawValue
        let restored = try JSONDecoder().decode(AppPreferences.self, from: JSONEncoder().encode(value))
        #expect(HistoryPeriod(rawValue: restored.periodID ?? "") == .threeYears)
        #expect(HistoryPeriod.visible.map(\.shortTitle) == ["3M", "1A", "3A", "5A", "Max"])
    }
}
