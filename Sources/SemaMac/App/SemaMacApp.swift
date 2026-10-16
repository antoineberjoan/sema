import AppKit
import SwiftUI
import UserNotifications

@main
struct SemaMacApp: App {
    @NSApplicationDelegateAdaptor(SemaAppDelegate.self) private var appDelegate
    @State private var store = AppStore()

    var body: some Scene {
        Window("sema", id: "workspace") {
            WorkspaceView().environment(store).tint(store.palette.controlAccent)
                .environment(\.semaAccent, store.palette.accent)
                .environment(\.locale, Locale(identifier: "fr_FR"))
                .preferredColorScheme(store.appearance.colorScheme)
                .background {
                    MenuRibbonAttachment(store: store, appDelegate: appDelegate).frame(width: 0, height: 0)
                }
                .sheet(isPresented: $store.isOnboardingPresented) {
                    OnboardingView(initialSelection: store.preferences.followedSeriesIDs,
                        selectSeries: store.followStarterSeries, finish: store.finishOnboarding)
                        .environment(store).tint(store.palette.controlAccent)
                        .environment(\.semaAccent, store.palette.accent)
                        .environment(\.locale, Locale(identifier: "fr_FR"))
                }
        }
        .defaultSize(width: 1120, height: 760)
        .windowStyle(.automatic)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            SidebarCommands()
            SemaCommands(store: store, showRibbon: appDelegate.toggleRibbon)
        }

        Settings {
            SemaSettingsView().environment(store).tint(store.palette.controlAccent)
                .environment(\.semaAccent, store.palette.accent)
                .preferredColorScheme(store.appearance.colorScheme)
        }
    }
}

@MainActor
final class SemaAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var menuRibbon: MenuRibbonController?

    func installRibbon(store: AppStore, openWorkspace: @escaping () -> Void, openSettings: @escaping () -> Void) {
        guard menuRibbon == nil else { return }
        menuRibbon = MenuRibbonController(store: store, openWorkspace: openWorkspace, openSettings: openSettings)
    }

    func toggleRibbon() { menuRibbon?.toggle() }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationWillTerminate(_ notification: Notification) { menuRibbon?.tearDown() }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
