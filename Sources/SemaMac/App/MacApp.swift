// Assemble les scènes SwiftUI et le cycle de vie de l’app accessible depuis la barre de menus.
import AppKit
import SemaDesign
import SwiftUI

@main
struct MacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = AppStore()

    var body: some Scene {
        Window("sema", id: "workspace") {
            WorkspaceScreen().environment(store).tint(DesignColor.accentControl(store.palette))
                .environment(\.palette, store.palette)
                .environment(\.locale, .french)
                .preferredColorScheme(store.appearance.colorScheme)
                .background {
                    MenuRibbonAttachment(store: store, appDelegate: appDelegate).frame(width: .zero, height: .zero)
                }
                .sheet(isPresented: $store.isOnboardingPresented) {
                    OnboardingScreen(initialSelection: store.preferences.followedSeriesIDs,
                        selectSeries: store.followStarterSeries, finish: store.finishOnboarding)
                        .environment(store).tint(DesignColor.accentControl(store.palette))
                        .environment(\.palette, store.palette)
                        .environment(\.locale, .french)
                }
        }
        .defaultSize(width: DesignLayout.macAppDefaultWidth, height: DesignLayout.macAppDefaultHeight)
        .windowStyle(.automatic)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            AppCommands(store: store, showRibbon: appDelegate.toggleRibbon)
        }

        Settings {
            SettingsScreen().environment(store).tint(DesignColor.accentControl(store.palette))
                .environment(\.palette, store.palette)
                .preferredColorScheme(store.appearance.colorScheme)
        }
    }
}
