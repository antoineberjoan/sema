import AppKit
import SwiftUI
import UserNotifications

@main
struct SemaMacApp: App {
    @NSApplicationDelegateAdaptor(SemaAppDelegate.self) private var appDelegate
    @State private var store = AppStore()
    @State private var isMenuInserted = true

    var body: some Scene {
        Window("Sema", id: "workspace") {
            WorkspaceView().environment(store).tint(SemaTheme.accent)
                .environment(\.locale, Locale(identifier: "fr_FR"))
        }
        .defaultSize(width: 1120, height: 760)
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
        }

        MenuBarExtra(isInserted: $isMenuInserted) {
            MenuPanelView().environment(store).tint(SemaTheme.accent)
                .environment(\.locale, Locale(identifier: "fr_FR"))
        } label: {
            Image(nsImage: SemaTheme.menuBarIcon).accessibilityLabel("Sema")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SemaSettingsView().environment(store).tint(SemaTheme.accent)
        }
    }
}

@MainActor
final class SemaAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
