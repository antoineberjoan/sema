import SwiftUI

struct SemaSettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var apiKey = ""
    var body: some View {
        TabView {
            Form {
                Section("Banque de France · Webstat") {
                    LabeledContent("Clé personnelle") { Text(store.hasWebstatKey ? "Enregistrée dans le Trousseau" : "À renseigner") }
                    SecureField(store.hasWebstatKey ? "Nouvelle clé Webstat" : "Votre clé API Webstat", text: $apiKey)
                        .textContentType(.password).privacySensitive()
                        .accessibilityLabel("Clé API Webstat")
                    HStack {
                        Button(store.isLoading ? "Connexion…" : "Enregistrer et connecter") {
                            Task { if await store.connectWebstat(apiKey: apiKey) { apiKey = "" } }
                        }
                        .disabled(store.isLoading || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if store.hasWebstatKey {
                            Button("Retirer la clé", role: .destructive) { Task { await store.removeWebstatKey() } }
                                .disabled(store.isLoading)
                        }
                    }
                    Link("Obtenir une clé sur Webstat", destination: URL(string: "https://webstat.banque-france.fr/login/")!)
                    Text("Votre clé reste dans le Trousseau de ce Mac et est transmise uniquement à Webstat. Elle ne fait pas partie du cache ni des préférences.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    if let error = store.webstatError {
                        Text(error).font(.system(size: 11)).foregroundStyle(.red)
                    }
                }
                Section("Sources") {
                    LabeledContent("Repères") { Text(store.hasLoadedWebstat ? "Banque de France · Webstat" : "Démonstration") }
                    Text("13 repères : épargne réglementée, taux BCE, €STR, inflation, changes, crédit immobilier et emprunt français à dix ans. Historique jusqu’à cinq ans selon la série. Les fonds restent fictifs.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    HStack {
                        Button("Actualiser Webstat") { Task { await store.refreshWebstat() } }
                            .disabled(store.isLoading || !store.hasWebstatKey)
                        Button("Afficher la démonstration") { store.restoreDemo() }.disabled(store.isLoading)
                    }
                    Text("Les données sources sont consultables gratuitement auprès de la Banque de France, de la BCE et d’Eurostat. Chaque repère indique sa période et sa source.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
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
        .padding(15).frame(width: 620, height: 650)
        .task { await store.checkWebstatKey() }
        .onDisappear { apiKey = "" }
    }
}
