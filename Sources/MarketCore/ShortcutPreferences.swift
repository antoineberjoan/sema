// Conserve les deux raccourcis personnels sans dépendre des API clavier de macOS.
import Foundation

public enum ShortcutAction: String, CaseIterable, Sendable, Identifiable {
    case ribbon, workspace
    public var id: String { rawValue }
}

public struct AppShortcut: Codable, Equatable, Sendable {
    public struct Modifiers: OptionSet, Codable, Sendable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }
        public static let control = Self(rawValue: 1)
        public static let option = Self(rawValue: 2)
        public static let shift = Self(rawValue: 4)
        public static let command = Self(rawValue: 8)
    }

    public let keyCode: UInt16
    public let modifiers: Modifiers
    public let key: String

    public init(keyCode: UInt16, modifiers: Modifiers, key: String) {
        self.keyCode = keyCode; self.modifiers = modifiers; self.key = key
    }

    public var isValid: Bool {
        keyCode < 128 && !key.isEmpty && !modifiers.intersection([.control, .option, .command]).isEmpty
            && modifiers.rawValue & ~UInt8(15) == 0
    }

    public func matches(_ other: AppShortcut) -> Bool { keyCode == other.keyCode && modifiers == other.modifiers }
}

public struct ShortcutPreferences: Codable, Equatable, Sendable {
    public var ribbon: AppShortcut?
    public var workspace: AppShortcut?

    public init(ribbon: AppShortcut?, workspace: AppShortcut?) { self.ribbon = ribbon; self.workspace = workspace }

    public static let standard = Self(
        ribbon: AppShortcut(keyCode: 11, modifiers: [.control, .option], key: "B"),
        workspace: AppShortcut(keyCode: 4, modifiers: [.control, .shift], key: "H"))

    // Only the retired default changes; custom bindings and disabled actions remain intact.
    public func migrated() -> Self {
        let previousWorkspace = AppShortcut(keyCode: 4, modifiers: [.control, .option], key: "H")
        guard workspace?.matches(previousWorkspace) == true else { return self }
        var result = self
        result.workspace = Self.standard.workspace
        return result
    }

    public subscript(action: ShortcutAction) -> AppShortcut? {
        get { switch action { case .ribbon: ribbon; case .workspace: workspace } }
        set { switch action { case .ribbon: ribbon = newValue; case .workspace: workspace = newValue } }
    }
}
