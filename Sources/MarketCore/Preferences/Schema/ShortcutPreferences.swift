// Raccourcis globaux choisis par l’utilisateur et leurs valeurs par défaut.
import Foundation

public struct ShortcutPreferences: Codable, Equatable, Sendable {
    public var ribbon: AppShortcut?
    public var workspace: AppShortcut?
    /// Absent par défaut : la recherche globale reste éteinte tant que la personne n’a pas choisi ses touches.
    public var search: AppShortcut?

    public init(ribbon: AppShortcut?, workspace: AppShortcut?, search: AppShortcut? = nil) {
        self.ribbon = ribbon; self.workspace = workspace; self.search = search
    }

    // Codes virtuels macOS de B et H (`kVK_ANSI_B`, `kVK_ANSI_H`), fixés par le clavier physique.
    private static let keyB: UInt16 = 11
    static let keyH: UInt16 = 4

    public static let standard = Self(
        ribbon: AppShortcut(keyCode: keyB, modifiers: [.control, .option], key: "B"),
        workspace: AppShortcut(keyCode: keyH, modifiers: [.control, .shift], key: "H"))

    public subscript(action: ShortcutAction) -> AppShortcut? {
        get { switch action { case .ribbon: ribbon; case .workspace: workspace; case .search: search } }
        set {
            switch action {
            case .ribbon: ribbon = newValue
            case .workspace: workspace = newValue
            case .search: search = newValue
            }
        }
    }
}
