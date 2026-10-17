// Assemble les scènes SwiftUI et le cycle de vie de l’app accessible depuis la barre de menus.
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
    private var refreshController: RefreshController?

    func installRibbon(store: AppStore, openWorkspace: @escaping () -> Void, openSettings: @escaping () -> Void) {
        guard menuRibbon == nil else { return }
        menuRibbon = MenuRibbonController(store: store, openWorkspace: openWorkspace, openSettings: openSettings)
        store.globalShortcuts.perform = { [weak self, weak store] action in
            guard let self, let store else { return }
            switch action {
            case .ribbon: self.menuRibbon?.toggle()
            case .workspace:
                if !store.isSearchPresented && !store.isAlertSheetPresented && !store.isOnboardingPresented {
                    store.section = .overview
                }
                self.menuRibbon?.showWorkspace()
            }
        }
        store.activateShortcuts()
        shortcuts = store.globalShortcuts
        let refresh = RefreshController(store: store)
        refreshController = refresh
        refresh.start()
    }

    func toggleRibbon() { menuRibbon?.toggle() }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private var shortcuts: GlobalShortcuts?

    func applicationWillTerminate(_ notification: Notification) {
        refreshController?.stop()
        shortcuts?.tearDown(); menuRibbon?.tearDown()
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
