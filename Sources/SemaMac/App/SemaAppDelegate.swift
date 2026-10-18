// Installe le bandeau et l’actualisation quotidienne, et répond aux raccourcis globaux et aux notifications du système.
import AppKit
import UserNotifications

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
        let event = NSAppleEventManager.shared().currentAppleEvent
        let isLoginLaunch = event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        if isLoginLaunch {
            for window in NSApplication.shared.windows { window.orderOut(nil) }
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
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
