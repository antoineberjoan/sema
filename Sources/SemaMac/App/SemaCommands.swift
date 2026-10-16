import SwiftUI

struct SemaCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let store: AppStore

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Rechercher un repère…") {
                openWindow(id: "workspace")
                store.isSearchPresented = true
            }
            .keyboardShortcut("k")
            .disabled(store.isAlertSheetPresented)
        }
        CommandMenu("Navigation") {
            Button("Panorama") { navigate(to: .overview) }.keyboardShortcut("1").disabled(hasModal)
            Button("Favoris") { navigate(to: .favorites) }.keyboardShortcut("2").disabled(hasModal)
            Button("Alertes") { navigate(to: .alerts) }.keyboardShortcut("3").disabled(hasModal)
            Divider()
            Button("Créer une alerte") {
                openWindow(id: "workspace")
                store.isAlertSheetPresented = true
            }
            .disabled(hasModal)
            Button("Actualiser Webstat") { Task { await store.refreshWebstat() } }
                .keyboardShortcut("r").disabled(store.isLoading || !store.hasWebstatKey)
        }
    }

    private var hasModal: Bool { store.isSearchPresented || store.isAlertSheetPresented }

    private func navigate(to section: WorkspaceSection) {
        store.section = section
        openWindow(id: "workspace")
    }
}
