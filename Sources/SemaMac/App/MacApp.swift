// Assemble les scènes SwiftUI et le cycle de vie de l’app accessible depuis la barre de menus.
import AppKit
import SwiftUI

@main
struct MacApp: App {
    private static let defaultWidth: CGFloat = 1120
    private static let defaultHeight: CGFloat = 760
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = AppStore()

    var body: some Scene {
        Window("sema", id: "workspace") {
            WorkspaceView().environment(store).tint(store.palette.controlAccent)
                .environment(\.semaAccent, store.palette.accent)
                .environment(\.locale, .french)
                .preferredColorScheme(store.appearance.colorScheme)
                .background {
                    MenuRibbonAttachment(store: store, appDelegate: appDelegate).frame(width: 0, height: 0)
                }
                .sheet(isPresented: $store.isOnboardingPresented) {
                    OnboardingView(initialSelection: store.preferences.followedSeriesIDs,
                        selectSeries: store.followStarterSeries, finish: store.finishOnboarding)
                        .environment(store).tint(store.palette.controlAccent)
                        .environment(\.semaAccent, store.palette.accent)
                        .environment(\.locale, .french)
                }
        }
        .defaultSize(width: Self.defaultWidth, height: Self.defaultHeight)
        .windowStyle(.automatic)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            AppCommands(store: store, showRibbon: appDelegate.toggleRibbon)
        }

        Settings {
            SettingsView().environment(store).tint(store.palette.controlAccent)
                .environment(\.semaAccent, store.palette.accent)
                .preferredColorScheme(store.appearance.colorScheme)
        }
    }
}
