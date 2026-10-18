// Actions accessibles par un raccourci global.
import Foundation

public enum ShortcutAction: String, CaseIterable, Sendable, Identifiable {
    case ribbon, workspace
    public var id: String { rawValue }
}
