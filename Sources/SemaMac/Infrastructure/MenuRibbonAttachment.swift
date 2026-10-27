// Relie le contrôleur du bandeau aux actions d’ouverture des fenêtres SwiftUI.
import AppKit
import SwiftUI

struct MenuRibbonAttachment: NSViewRepresentable {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    let store: AppStore
    let appDelegate: AppDelegate

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
