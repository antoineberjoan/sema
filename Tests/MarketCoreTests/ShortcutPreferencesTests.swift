// Vérifie que les raccourcis ajoutés préservent les anciennes préférences et les choix personnels.
import Foundation
import Testing
@testable import MarketCore

struct ShortcutPreferencesTests {
    @Test func oldPreferencesKeepTheirFavoritesWithoutRewritingTheFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-shortcuts-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("preferences.json")
        let data = Data("""
        {"schemaVersion":2,"favoriteIDs":["EXR.D.USD.EUR.SP00.A"],"followedSeriesIDs":["EXR.D.USD.EUR.SP00.A"],"alerts":[],"notificationsEnabled":false}
        """.utf8)
        try data.write(to: file)
        let loaded = try PreferencesStore(fileURL: file).load()
        #expect(loaded.shortcuts == nil)
        #expect(loaded.favoriteIDs == ["EXR.D.USD.EUR.SP00.A"])
        #expect(try Data(contentsOf: file) == data)
    }

    @Test func customAndDisabledBindingsSurviveRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-shortcuts-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PreferencesStore(fileURL: directory.appendingPathComponent("preferences.json"))
        let custom = AppShortcut(keyCode: 49, modifiers: [.control, .shift], key: "espace")
        let expected = AppPreferences(favoriteIDs: [], themeID: "polar", appearanceID: "dark",
            followedSeriesIDs: [], shortcuts: ShortcutPreferences(ribbon: custom, workspace: nil))
        try store.save(expected)
        let loaded = try store.load()
        #expect(loaded == expected)
        #expect(loaded.shortcuts?[.workspace] == nil)
        #expect(loaded.shortcuts?[.ribbon] == custom)
    }

    @Test func shiftAloneAndUnknownModifierBitsCannotBecomeGlobalShortcuts() {
        #expect(!AppShortcut(keyCode: 11, modifiers: .shift, key: "B").isValid)
        #expect(!AppShortcut(keyCode: 11, modifiers: .init(rawValue: 32), key: "B").isValid)
        #expect(!AppShortcut(keyCode: 255, modifiers: .command, key: "B").isValid)
        #expect(AppShortcut(keyCode: 11, modifiers: [.control, .option], key: "B").isValid)
        #expect(AppShortcut(keyCode: 11, modifiers: [.control, .option], key: "b").matches(ShortcutPreferences.standard.ribbon!))
    }
}
