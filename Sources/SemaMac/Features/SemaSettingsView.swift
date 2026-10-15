import SwiftUI

struct SemaSettingsView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        TabView {
            Form {
                Section("Sources") {
                    LabeledContent("Devises") { Text(store.hasLoadedECB ? "BCE · taux de référence publiés" : "Démonstration") }
                    Text("L’actualisation récupère les taux EUR/USD, EUR/JPY et EUR/CHF des 90 derniers jours. Les autres indicateurs et tous les fonds restent fictifs.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    HStack {
                        Button("Actualiser depuis la BCE") { Task { await store.refreshECB() } }.disabled(store.isLoading)
                        Button("Afficher la démonstration") { store.restoreDemo() }
                    }
                }
                Section("Notifications") {
                    Toggle("Autoriser les notifications système pour les tests", isOn: Binding(
                        get: { store.preferences.notificationsEnabled },
                        set: { value in Task { await store.setNotificationsEnabled(value) } }
                    ))
                    Text("Le test reste visible dans Sema même sans autorisation système. Aucune surveillance automatique ou notification distante n’est active.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Général", systemImage: "slider.horizontal.3") }
            VStack(spacing: 14) {
                SemaMark(size: 64)
                Text("Sema").font(.system(size: 28, weight: .medium)).tracking(-1)
                Text("Vos repères, à portée de main.").foregroundStyle(.secondary)
                Text("Version 0.1.0 · macOS 14+").font(.system(size: 11)).foregroundStyle(.secondary)
                Text("SwiftUI · AppKit · Swift Charts\nAucune bibliothèque externe.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem { Label("À propos", systemImage: "info.circle") }
        }
        .padding(15).frame(width: 560, height: 440)
    }
}
