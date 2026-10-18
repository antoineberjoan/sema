// Combinaison de touches enregistrée sans dépendre des API clavier de macOS.
import Foundation

public struct AppShortcut: Codable, Equatable, Sendable {
    public struct Modifiers: OptionSet, Codable, Sendable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }
        public static let control = Self(rawValue: 1)
        public static let option = Self(rawValue: 2)
        public static let shift = Self(rawValue: 4)
        public static let command = Self(rawValue: 8)
        public static let all: Self = [.control, .option, .shift, .command]
    }

    /// Les codes de touche virtuels de macOS tiennent sur sept bits.
    private static let keyCodeLimit: UInt16 = 128

    public let keyCode: UInt16
    public let modifiers: Modifiers
    public let key: String

    public init(keyCode: UInt16, modifiers: Modifiers, key: String) {
        self.keyCode = keyCode; self.modifiers = modifiers; self.key = key
    }

    public var isValid: Bool {
        keyCode < Self.keyCodeLimit && !key.isEmpty && !modifiers.intersection([.control, .option, .command]).isEmpty
            && Modifiers.all.isSuperset(of: modifiers)
    }

    public func matches(_ other: AppShortcut) -> Bool { keyCode == other.keyCode && modifiers == other.modifiers }
}
