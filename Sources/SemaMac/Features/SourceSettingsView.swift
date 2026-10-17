// Réunit les sources activables et la connexion Webstat sans modifier les données en cache.
import SwiftUI
import MarketCore

struct SourceSettingsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Form {
            Section("Webstat") { WebstatConnectionView() }
            Section("Catalogues") {
                sourceRow(id: "webstat", title: "Banque de France · Webstat")
                ForEach(StatisticalSource.allCases) { source in
                    sourceRow(id: source.rawValue, title: source.title)
                }
            }
            .help("Désactiver une source met ses alertes en pause et conserve ses historiques.")
        }
        .formStyle(.grouped)
    }

    private func sourceRow(id: String, title: String) -> some View {
        Toggle(isOn: Binding(get: { store.isSourceEnabled(id) }, set: { store.setSourceEnabled(id, enabled: $0) })) {
            HStack {
                Text(title)
                Spacer()
                let count = store.sourceSeriesCount(id)
                if count > 0 {
                    Text("\(count) \(count == 1 ? "repère" : "repères")")
                        .font(.callout).foregroundStyle(.secondary)
                }
            }.padding(.vertical, SemaTheme.minorSpacing / 2)
        }.toggleStyle(.switch).accessibilityLabel("Activer \(title)")
    }
}

// Partage le champ protégé et la validation entre les réglages et la première connexion.
struct WebstatConnectionView: View {
    @Environment(AppStore.self) private var store
    @State private var apiKey = ""
    var didConnect: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: SemaTheme.majorSpacing) {
            if store.hasWebstatKey {
                Label("Connecté", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(store.palette.accent)
            }
            HStack(spacing: SemaTheme.minorSpacing) {
                SecureField(store.hasWebstatKey ? "Nouvelle clé API" : "Clé API personnelle", text: $apiKey)
                    .textFieldStyle(.roundedBorder).textContentType(.password)
                    .privacySensitive().accessibilityLabel("Clé API Webstat")
                    .onSubmit(connect)
                Button(store.isLoading ? "Connexion…" : store.hasWebstatKey ? "Remplacer" : "Connecter", action: connect)
                    .disabled(!canConnect)
            }
            .controlSize(.large).disabled(!store.isSourceEnabled("webstat"))
            HStack {
                Link("Obtenir une clé", destination: URL(string: "https://webstat.banque-france.fr/login/")!)
                Spacer()
                if store.hasWebstatKey {
                    Button("Retirer la clé", role: .destructive) { Task { await store.removeWebstatKey() } }
                        .disabled(store.isLoading)
                }
            }.font(.callout).buttonStyle(.link)
            if !store.isSourceEnabled("webstat") {
                Text("Activez Webstat dans les catalogues.").font(.callout).foregroundStyle(.secondary)
            }
            if let error = store.webstatError {
                Text(error).font(.callout).foregroundStyle(.red).textSelection(.enabled)
            }
        }
        .padding(.vertical, SemaTheme.minorSpacing)
        .help("Clé conservée dans le Trousseau, transmise uniquement à Webstat.")
        .onDisappear { apiKey = "" }
    }

    private var canConnect: Bool {
        !store.isLoading && store.isSourceEnabled("webstat")
            && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func connect() {
        guard canConnect else { return }
        Task {
            if await store.connectWebstat(apiKey: apiKey) {
                apiKey = ""
                didConnect()
            }
        }
    }
}
