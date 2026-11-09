// Place et ferme le panneau macOS des favoris en coordonnant écrans, événements et transitions.
import AppKit
import SwiftUI
import QuartzCore

/// A native status item owns the panel independently of the hub's window lifetime.
@MainActor
final class MenuRibbonController: NSObject {
    private static let releasesURL = URL(string: "https://github.com/antoineberjoan/homebrew-sema/releases")!
    private let store: AppStore
    private let openWorkspace: () -> Void
    private let openSettings: () -> Void
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var screenObserver: NSObjectProtocol?
    private var isPresented = false
    private var transition = UUID()
    /// A click elsewhere, Escape or another app closes the ribbon; ⌘K opens the search from it.
    private lazy var dismissal = PanelDismissal(panel: panel, ignoring: { [weak self] in [self?.statusItem.button?.window] },
        dismiss: { [weak self] in self?.dismiss() }, handleKey: { [weak self] event in
            guard let self, event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "k" else { return false }
            self.showWorkspace(); self.store.isSearchPresented = true
            return true
        })
    private lazy var hostedContent = NSHostingView(rootView: ribbonContent(presentationID: nil))

    private func ribbonContent(presentationID: UUID?) -> AnyView {
        AnyView(MenuRibbonView(presentationID: presentationID,
            openWorkspace: { [weak self] in self?.showWorkspace() },
            openSettings: { [weak self] in self?.showSettings() }).environment(store))
    }

    private lazy var panel: FloatingPanel = {
        let panel = FloatingPanel.make(title: "Vos favoris · sema", identifier: "sema-favorites-ribbon")
        // Each card owns its glass. The panel and the gaps remain transparent.
        let container = NSView()
        hostedContent.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hostedContent)
        NSLayoutConstraint.activate([
            hostedContent.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostedContent.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hostedContent.topAnchor.constraint(equalTo: container.topAnchor),
            hostedContent.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        panel.contentView = container
        return panel
    }()

    init(store: AppStore, openWorkspace: @escaping () -> Void, openSettings: @escaping () -> Void) {
        self.store = store; self.openWorkspace = openWorkspace; self.openSettings = openSettings
        super.init()
        if let button = statusItem.button {
            button.image = Theme.menuBarIcon
            button.imagePosition = .imageOnly
            button.toolTip = "sema · Vos favoris"
            button.setAccessibilityLabel("sema, afficher les favoris")
            button.target = self; button.action = #selector(handleStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, self.isPresented else { return }
                    self.dismiss()
                }
            }
    }

    @objc private func handleStatusItemClick(_ button: NSStatusBarButton) {
        guard let event = NSApplication.shared.currentEvent, event.type == .rightMouseUp else {
            toggle(); return
        }
        dismiss()
        let menu = NSMenu()
        let settings = menu.addItem(withTitle: "Réglages…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        settings.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(.separator())
        let updates = menu.addItem(withTitle: "Rechercher des mises à jour…", action: #selector(showReleases), keyEquivalent: "")
        updates.target = self
        updates.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)
        updates.toolTip = "Voir les versions disponibles et leurs téléchargements dans le navigateur."
        menu.addItem(.separator())
        let quit = menu.addItem(withTitle: "Quitter sema", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApplication.shared
        quit.image = NSImage(systemSymbolName: "xmark.rectangle", accessibilityDescription: nil)
        NSMenu.popUpContextMenu(menu, with: event, for: button)
    }

    @objc func toggle() {
        if isPresented { dismiss(); return }
        if store.isOnboardingPresented || store.isSearchPresented || store.isAlertSheetPresented {
            openWorkspace(); return
        }
        let screen = FloatingPanel.screenUnderPointer ?? statusItem.button?.window?.screen ?? NSScreen.main
        guard let screen else { return }
        let target = store.ribbonPosition.frame(in: screen)
        let offset = store.ribbonPosition.revealOffset
        transition = UUID(); isPresented = true
        hostedContent.rootView = ribbonContent(presentationID: transition)
        if !panel.isVisible {
            panel.setFrame(target.offsetBy(dx: offset.dx, dy: offset.dy), display: false)
            panel.alphaValue = 0
        }
        panel.makeKeyAndOrderFront(nil)
        statusItem.button?.highlight(true)
        dismissal.start()
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.setFrame(target, display: true); panel.alphaValue = 1
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = MenuRibbonLayout.revealDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(target, display: true)
                panel.animator().alphaValue = 1
            }
        }
    }

    func dismiss() {
        guard isPresented else { return }
        isPresented = false; transition = UUID()
        let generation = transition
        dismissal.stop(); statusItem.button?.highlight(false)
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.orderOut(nil)
            hostedContent.rootView = ribbonContent(presentationID: nil)
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = MenuRibbonLayout.dismissDuration
                panel.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                Task { @MainActor in
                    guard let self, self.transition == generation, !self.isPresented else { return }
                    self.panel.orderOut(nil)
                    self.hostedContent.rootView = self.ribbonContent(presentationID: nil)
                }
            }
        }
    }

    @objc func showWorkspace() { dismiss(); openWorkspace() }
    @objc private func showSettings() { dismiss(); openSettings() }
    @objc private func showReleases() {
        NSWorkspace.shared.open(Self.releasesURL)
    }

    func tearDown() {
        transition = UUID(); isPresented = false
        dismissal.stop()
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        screenObserver = nil
        panel.orderOut(nil)
        NSStatusBar.system.removeStatusItem(statusItem)
    }
}
