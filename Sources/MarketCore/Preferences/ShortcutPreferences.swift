// Raccourcis globaux choisis par l’utilisateur et leurs valeurs par défaut.
import Foundation

public struct ShortcutPreferences: Codable, Equatable, Sendable {
    public var ribbon: AppShortcut?
    public var workspace: AppShortcut?

    public init(ribbon: AppShortcut?, workspace: AppShortcut?) { self.ribbon = ribbon; self.workspace = workspace }

    // Codes virtuels macOS de B et H (`kVK_ANSI_B`, `kVK_ANSI_H`), fixés par le clavier physique.
    private static let keyB: UInt16 = 11
    private static let keyH: UInt16 = 4

    public static let standard = Self(
        ribbon: AppShortcut(keyCode: keyB, modifiers: [.control, .option], key: "B"),
        workspace: AppShortcut(keyCode: keyH, modifiers: [.control, .shift], key: "H"))
    private static let retiredWorkspace = AppShortcut(keyCode: keyH, modifiers: [.control, .option], key: "H")

    // Seul l’ancien raccourci par défaut change ; les choix personnels et les actions désactivées restent intacts.
    public func migrated() -> Self {
        guard workspace?.matches(Self.retiredWorkspace) == true else { return self }
        var result = self
        result.workspace = Self.standard.workspace
        return result
    }

    public subscript(action: ShortcutAction) -> AppShortcut? {
        get { switch action { case .ribbon: ribbon; case .workspace: workspace } }
        set { switch action { case .ribbon: ribbon = newValue; case .workspace: workspace = newValue } }
    }
}
