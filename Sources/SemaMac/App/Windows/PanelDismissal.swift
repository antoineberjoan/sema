// Ferme un panneau flottant au clic extérieur, à Échap et quand l’espace ou l’app active change.
import AppKit
import Carbon

@MainActor
final class PanelDismissal {
    private let panel: NSPanel
    private let ignoredWindows: () -> [NSWindow?]
    private let dismiss: () -> Void
    private let handleKey: (NSEvent) -> Bool
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var workspaceObservers: [NSObjectProtocol] = []

    /// `handleKey` voit chaque touche en premier et répond true pour la consommer ; une touche Échap non gérée ferme le panneau.
    init(panel: NSPanel, ignoring ignoredWindows: @escaping () -> [NSWindow?] = { [] },
         dismiss: @escaping () -> Void, handleKey: @escaping (NSEvent) -> Bool = { _ in false }) {
        self.panel = panel; self.ignoredWindows = ignoredWindows; self.dismiss = dismiss; self.handleKey = handleKey
    }

    func start() {
        stop()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.dismiss() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            let consumed = MainActor.assumeIsolated {
                guard let self else { return false }
                if event.type == .keyDown {
                    if self.handleKey(event) { return true }
                    if Int(event.keyCode) == kVK_Escape { self.dismiss(); return true }
                } else if event.window !== self.panel, !self.ignoredWindows().contains(where: { $0 === event.window }) {
                    self.dismiss()
                }
                return false
            }
            return consumed ? nil : event
        }
        for name in [NSWorkspace.activeSpaceDidChangeNotification, NSWorkspace.didActivateApplicationNotification] {
            workspaceObservers.append(NSWorkspace.shared.notificationCenter.addObserver(
                forName: name, object: nil, queue: .main) { [weak self] notification in
                    let activatedPID = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
                    MainActor.assumeIsolated {
                        if activatedPID == ProcessInfo.processInfo.processIdentifier { return }
                        self?.dismiss()
                    }
                })
        }
    }

    func stop() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }; localMonitor = nil
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }; globalMonitor = nil
        workspaceObservers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        workspaceObservers = []
    }
}
