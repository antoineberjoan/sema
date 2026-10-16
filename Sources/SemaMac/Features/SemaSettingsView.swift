import SwiftUI

struct SemaSettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openWindow) private var openWindow
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
                    Text("Composez votre sélection dans Explorer : taux, inflation, crédit, indices, montants et autres séries accessibles avec votre clé Webstat. « Tout » charge l’historique publié à la demande.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    HStack {
                        Button("Actualiser Webstat") { Task { await store.refreshWebstat() } }
                            .disabled(store.isLoading || !store.hasWebstatKey)
                        Button("Afficher la démonstration") { store.restoreDemo() }.disabled(store.isLoading)
                    }
                    Text("Les données sources sont consultables gratuitement auprès de la Banque de France, de la BCE et d’Eurostat. Chaque repère indique sa période et sa source.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Section("Premiers pas") {
                    Button("Revoir l’accueil de Sema") {
                        store.beginOnboarding()
                        openWindow(id: "workspace")
                    }
                    Text("Retrouvez la sélection de départ et la connexion Webstat. Vos repères personnels sont conservés.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Section("Notifications") {
                    Toggle("Autoriser les notifications de seuil et les tests", isOn: Binding(
                        get: { store.preferences.notificationsEnabled },
                        set: { value in Task { await store.setNotificationsEnabled(value) } }
                    ))
                    Text("Les seuils sont vérifiés à chaque actualisation Webstat. Les signaux restent visibles dans Sema sans notification système. Aucun contrôle quand l’app est quittée ou le Mac en veille.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Général", systemImage: "slider.horizontal.3") }
            Form {
                Section("Couleurs de Sema") {
                    Picker("Thème", selection: Binding(get: { store.palette }, set: { store.setPalette($0) })) {
                        ForEach(SemaPalette.allCases) { Text($0.title).tag($0) }
                    }
                    HStack(spacing: 8) {
                        ForEach(store.palette.swatches, id: \.self) { hex in
                            RoundedRectangle(cornerRadius: 8).fill(SemaPalette.swatch(hex))
                                .frame(height: 52).accessibilityLabel(String(format: "#%06X", hex))
                        }
                    }
                    .accessibilityElement(children: .combine)
                    Text("Le thème s’applique à la fenêtre, au panneau de barre de menus et aux graphiques. Les surfaces et la typographie restent natives ; les accents s’adaptent aux modes clair et sombre.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Apparence", systemImage: "paintpalette") }
            VStack(spacing: 14) {
                SemaMark(size: 64)
                Text("Sema").font(.system(size: 28, weight: .medium)).tracking(-1)
                Text("Vos repères, à portée de main.").foregroundStyle(.secondary)
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—") · macOS 14+")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
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
