// Partage le champ protégé et la validation de la clé Webstat entre les réglages et la première connexion.
import SwiftUI
import MarketCore

struct WebstatConnectionView: View {
    private static let spacing: CGFloat = 16
    @Environment(AppStore.self) private var store
    @State private var apiKey = ""
    var didConnect: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: Self.spacing) {
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
                Link("Obtenir une clé", destination: WebstatClient.loginURL)
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
