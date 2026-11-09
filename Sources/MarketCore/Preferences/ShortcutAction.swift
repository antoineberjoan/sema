// Actions accessibles par un raccourci global.
import Foundation

public enum ShortcutAction: String, CaseIterable, Sendable, Identifiable {
    // L’ordre fixe l’identifiant de chaque raccourci : toute nouvelle action s’ajoute à la fin.
    case ribbon, workspace, search
    public var id: String { rawValue }
}
