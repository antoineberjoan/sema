// Panneau flottant non activant, partagé par le bandeau et la recherche rapide : il reçoit le clavier sans activer l’app.
import AppKit

@MainActor
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Un panneau transparent sans bordure au-dessus des autres fenêtres ; chaque appelant dessine sa propre surface.
    static func make(title: String, identifier: String) -> FloatingPanel {
        let panel = FloatingPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                                  backing: .buffered, defer: true)
        panel.title = title
        panel.identifier = NSUserInterfaceItemIdentifier(identifier)
        panel.isOpaque = false; panel.backgroundColor = .clear
        panel.hasShadow = false; panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        return panel
    }

    /// L’écran où se trouve le pointeur, pour qu’un panneau s’ouvre là où la personne regarde.
    static var screenUnderPointer: NSScreen? {
        NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
    }
}
