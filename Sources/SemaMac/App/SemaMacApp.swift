// Assemble les scènes SwiftUI et le cycle de vie de l’app accessible depuis la barre de menus.
import AppKit
import SwiftUI

@main
struct SemaMacApp: App {
    private static let defaultWidth: CGFloat = 1120
    private static let defaultHeight: CGFloat = 760
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
        .defaultSize(width: Self.defaultWidth, height: Self.defaultHeight)
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
