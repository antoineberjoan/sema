import AppKit
import SwiftUI
import QuartzCore

/// A native status item owns the panel independently of the hub's window lifetime.
@MainActor
final class MenuRibbonController: NSObject {
    private let store: AppStore
    private let openWorkspace: () -> Void
    private let openSettings: () -> Void
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var screenObserver: NSObjectProtocol?
    private var isPresented = false
    private var transition = UUID()

    private lazy var panel: RibbonPanel = {
        let panel = RibbonPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                                backing: .buffered, defer: true)
        panel.title = "Vos favoris · Sema"
        panel.identifier = NSUserInterfaceItemIdentifier("sema-favorites-ribbon")
        panel.isOpaque = false; panel.backgroundColor = .clear
        panel.hasShadow = true; panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: MenuRibbonView(
            openWorkspace: { [weak self] in self?.showWorkspace() },
            openSettings: { [weak self] in self?.showSettings() },
            dismiss: { [weak self] in self?.dismiss() }).environment(store))
        return panel
    }()

    init(store: AppStore, openWorkspace: @escaping () -> Void, openSettings: @escaping () -> Void) {
        self.store = store; self.openWorkspace = openWorkspace; self.openSettings = openSettings
        super.init()
        if let button = statusItem.button {
            button.image = SemaTheme.menuBarIcon
            button.imagePosition = .imageOnly
            button.toolTip = "Sema · Vos favoris"
            button.setAccessibilityLabel("Sema, afficher les favoris")
            button.target = self; button.action = #selector(toggle)
        }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, self.isPresented else { return }
                    self.dismiss()
                }
            }
    }

    @objc func toggle() {
        if isPresented { dismiss(); return }
        if store.isOnboardingPresented || store.isSearchPresented || store.isAlertSheetPresented {
            openWorkspace(); return
        }
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
            ?? statusItem.button?.window?.screen ?? NSScreen.main
        guard let screen else { return }
        let top = min(screen.visibleFrame.maxY, screen.frame.maxY - screen.safeAreaInsets.top)
        let target = NSRect(x: screen.frame.minX + MenuRibbonLayout.screenInset,
            y: top - MenuRibbonLayout.topGap - MenuRibbonLayout.height,
            width: screen.frame.width - 2 * MenuRibbonLayout.screenInset, height: MenuRibbonLayout.height)
        transition = UUID(); isPresented = true
        if !panel.isVisible {
            panel.setFrame(target.offsetBy(dx: 0, dy: MenuRibbonLayout.revealOffset), display: false)
            panel.alphaValue = 0
        }
        panel.makeKeyAndOrderFront(nil)
        statusItem.button?.highlight(true)
        installMonitors()
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
        removeMonitors(); statusItem.button?.highlight(false)
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.orderOut(nil)
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = MenuRibbonLayout.dismissDuration
                panel.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                Task { @MainActor in
                    guard let self, self.transition == generation, !self.isPresented else { return }
                    self.panel.orderOut(nil)
                }
            }
        }
    }

    private func showWorkspace() { dismiss(); openWorkspace() }
    private func showSettings() { dismiss(); openSettings() }

    private func installMonitors() {
        removeMonitors()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.dismiss() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            let consumed = MainActor.assumeIsolated {
                guard let self else { return false }
                if event.type == .keyDown {
                    if event.keyCode == 53 { self.dismiss(); return true }
                    if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "k" {
                        self.showWorkspace(); self.store.isSearchPresented = true; return true
                    }
                } else if event.window !== self.panel, event.window !== self.statusItem.button?.window {
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

    private func removeMonitors() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }; localMonitor = nil
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }; globalMonitor = nil
        workspaceObservers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        workspaceObservers = []
    }

    func tearDown() {
        transition = UUID(); isPresented = false
        removeMonitors()
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        screenObserver = nil
        panel.orderOut(nil)
        NSStatusBar.system.removeStatusItem(statusItem)
    }
}

@MainActor
private final class RibbonPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

struct MenuRibbonAttachment: NSViewRepresentable {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    let store: AppStore
    let appDelegate: SemaAppDelegate

    func makeNSView(context: Context) -> NSView {
        appDelegate.installRibbon(store: store, openWorkspace: {
            openWindow(id: "workspace")
            NSApplication.shared.activate(ignoringOtherApps: true)
        }, openSettings: {
            openSettings()
            NSApplication.shared.activate(ignoringOtherApps: true)
        })
        return NSView()
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
