// Installe le bandeau et l’actualisation quotidienne, et répond aux raccourcis globaux et aux notifications du système.
import AppKit
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var menuRibbon: MenuRibbonController?
    private var searchPanel: SearchPanelController?
    private var refreshController: RefreshController?
    private weak var store: AppStore?
    private var openWorkspace: () -> Void = {}

    func installRibbon(store: AppStore, openWorkspace: @escaping () -> Void, openSettings: @escaping () -> Void) {
        guard menuRibbon == nil else { return }
        self.store = store; self.openWorkspace = openWorkspace
        menuRibbon = MenuRibbonController(store: store, openWorkspace: openWorkspace, openSettings: openSettings)
        searchPanel = SearchPanelController(store: store, openWorkspace: openWorkspace)
        store.globalShortcuts.perform = { [weak self, weak store] action in
            guard let self, let store else { return }
            switch action {
            case .ribbon: self.menuRibbon?.toggle()
            case .workspace:
                if !store.isSearchPresented && !store.isAlertSheetPresented && !store.isOnboardingPresented {
                    store.section = .overview
                }
                self.menuRibbon?.showWorkspace()
            case .search: self.searchPanel?.toggle()
            }
        }
        store.activateShortcuts()
        shortcuts = store.globalShortcuts
        let refresh = RefreshController(store: store)
        refreshController = refresh
        store.rescheduleRefresh = { [weak refresh] in refresh?.check() }
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
        shortcuts?.tearDown(); menuRibbon?.tearDown(); searchPanel?.tearDown()
    }

    /// A click opens sema on what the notification is about: the series and its context, or a section.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse) async {
        guard let target = NotificationTarget(userInfo: response.notification.request.content.userInfo) else { return }
        await open(target)
    }

    private func open(_ target: NotificationTarget) {
        guard let store else { return }
        switch target {
        case .series(let id):
            guard let item = store.series.first(where: { $0.id == id }) else { return }
            store.show(item); store.section = .overview; store.isContextPresented = true
        case .section(let section): store.section = section
        }
        openWorkspace()
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
