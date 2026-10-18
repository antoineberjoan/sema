// Enregistre les raccourcis globaux choisis et signale leurs conflits.
import Foundation
import MarketCore

extension AppStore {
    var shortcuts: ShortcutPreferences { preferences.shortcuts ?? .standard }

    func activateShortcuts() {
        do { try globalShortcuts.apply(shortcuts); shortcutError = nil }
        catch { shortcutError = error.localizedDescription }
    }

    func setShortcut(_ shortcut: AppShortcut?, for action: ShortcutAction) {
        var next = preferences
        var bindings = shortcuts; bindings[action] = shortcut; next.shortcuts = bindings
        do { try globalShortcuts.apply(bindings) }
        catch {
            let message = error.localizedDescription
            activateShortcuts()
            shortcutError = message
            return
        }
        if commit(next) { shortcutError = nil }
        else {
            activateShortcuts()
            shortcutError = errorMessage
        }
    }
}
