// Vérifie les valeurs par défaut, la normalisation et la persistance des réglages du verre.
import Foundation
import Testing
@testable import MarketCore

struct RibbonGlassPreferencesTests {
    @Test func olderPreferencesKeepTheExistingGlassAndFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-glass-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("preferences.json")
        let previous = Data("""
        {"schemaVersion":2,"favoriteIDs":[],"followedSeriesIDs":[],"alerts":[],"notificationsEnabled":false,"themeID":"polar","appearanceID":"dark"}
        """.utf8)
        try previous.write(to: file)
        let loaded = try PreferencesStore(fileURL: file).load()
        #expect(loaded.ribbonGlass == nil)
        #expect((loaded.ribbonGlass ?? .standard).transparency == 0.75)
        #expect((loaded.ribbonGlass ?? .standard).tint == 0.5)
        #expect((loaded.ribbonGlass ?? .standard).grain == 0)
        #expect(try Data(contentsOf: file) == previous)
    }

    @Test func glassPersistsAndResetsWithoutChangingOtherChoices() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-glass-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PreferencesStore(fileURL: directory.appendingPathComponent("preferences.json"))
        let expected = AppPreferences(favoriteIDs: ["eurusd"], notificationsEnabled: true,
            themeID: "polar", appearanceID: "light", ribbonPositionID: "left", invertedCurrencyPairs: ["EUR/USD"],
            ribbonGlass: RibbonGlassPreferences(transparency: 0.9, tint: 0.8, grain: 0.3))
        try store.save(expected)
        var loaded = try store.load()
        #expect(loaded == expected)
        loaded.ribbonGlass = .standard
        try store.save(loaded)
        let reset = try store.load()
        #expect(reset.ribbonGlass == .standard)
        var restored = reset
        restored.ribbonGlass = expected.ribbonGlass
        #expect(restored == expected)
    }

    @Test func valuesStayWithinTheSupportedRange() throws {
        let outside = RibbonGlassPreferences(transparency: -0.5, tint: 3, grain: .nan)
        #expect(outside.transparency == 0)
        #expect(outside.tint == 1)
        #expect(outside.grain == 0)
        let invalid = RibbonGlassPreferences(transparency: .infinity, tint: -.infinity, grain: 2)
        #expect(invalid.transparency == 0.75)
        #expect(invalid.tint == 0.5)
        #expect(invalid.grain == 1)
        let decoded = try JSONDecoder().decode(RibbonGlassPreferences.self,
            from: Data("{\"transparency\":2,\"grain\":-1}".utf8))
        #expect(decoded == RibbonGlassPreferences(transparency: 1, tint: 0.5, grain: 0))
    }
}
