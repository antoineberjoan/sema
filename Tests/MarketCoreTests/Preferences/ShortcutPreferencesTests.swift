// Vérifie que les raccourcis ajoutés préservent les choix personnels et les préférences déjà écrites.
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
        let loaded = try PreferencesRepository(fileURL: file).load()
        #expect(loaded.shortcuts == nil)
        #expect(loaded.favoriteIDs == ["EXR.D.USD.EUR.SP00.A"])
        #expect(try Data(contentsOf: file) == data)
    }

    @Test func customAndDisabledBindingsSurviveRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-shortcuts-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PreferencesRepository(fileURL: directory.appendingPathComponent("preferences.json"))
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
    @Test func originalWorkspaceShortcutChangesWithoutReplacingCustomBindings() throws {
        let ribbon = AppShortcut(keyCode: 49, modifiers: [.control, .shift], key: "espace")
        let original = AppShortcut(keyCode: 4, modifiers: [.control, .option], key: "H")
        let preferences = AppPreferences(shortcuts: .init(ribbon: ribbon, workspace: original))
        #expect(try PreferencesMigration.upgrade(preferences).shortcuts?.workspace == ShortcutPreferences.standard.workspace)
        #expect(try PreferencesMigration.upgrade(preferences).shortcuts?.ribbon == ribbon)
        let custom = AppShortcut(keyCode: 46, modifiers: [.command, .shift], key: "M")
        #expect(PreferencesMigration.upgrade(ShortcutPreferences(ribbon: ribbon, workspace: custom)).workspace == custom)
        #expect(PreferencesMigration.upgrade(ShortcutPreferences(ribbon: nil, workspace: nil)).workspace == nil)
    }

    @Test func globalSearchIsOffByDefaultAndKeepsItsChoice() throws {
        #expect(ShortcutPreferences.standard.search == nil)
        #expect(ShortcutPreferences.standard[.search] == nil)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-shortcuts-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PreferencesRepository(fileURL: directory.appendingPathComponent("preferences.json"))
        let chosen = AppShortcut(keyCode: 49, modifiers: [.option], key: "espace")
        let expected = AppPreferences(shortcuts: ShortcutPreferences(ribbon: nil, workspace: nil, search: chosen))
        try store.save(expected)
        let loaded = try store.load()
        #expect(loaded.shortcuts?[.search] == chosen)
        #expect(loaded.shortcuts?[.ribbon] == nil)
        #expect(loaded.shortcuts.map(PreferencesMigration.upgrade)?.search == chosen)
    }
}
