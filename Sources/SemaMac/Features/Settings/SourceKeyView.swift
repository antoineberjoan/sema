// Saisit, remplace ou retire la clé personnelle d’une source, dans les réglages comme à la première connexion.
import SwiftUI
import MarketCore

struct SourceKeyView: View {
    @Environment(AppStore.self) private var store
    @State private var key = ""
    let source: String
    var didConnect: () -> Void = {}

    private var provider: MarketProvider? { MarketProvider(rawValue: source) }
    private var title: String { provider?.title ?? "Webstat" }
    private var signupURL: URL { provider?.signupURL ?? WebstatClient.loginURL }
    private var connected: Bool { provider.map { store.connectedMarkets.contains($0) } ?? store.hasWebstatKey }
    private var connecting: Bool { provider.map { store.connectingMarkets.contains($0) } ?? store.isLoading }
    private var error: String? { provider.map { store.marketErrors[$0] } ?? store.webstatError }
    private var enabled: Bool { store.isSourceEnabled(source) }
    private var canConnect: Bool { !connecting && enabled && !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: SemaTheme.majorSpacing) {
            if connected {
                Label("Connecté", systemImage: "checkmark.circle.fill").foregroundStyle(store.palette.accent)
            }
            HStack(spacing: SemaTheme.minorSpacing) {
                SecureField(connected ? "Nouvelle clé API" : "Clé API personnelle", text: $key)
                    .textFieldStyle(.roundedBorder).textContentType(.password).privacySensitive()
                    .accessibilityLabel("Clé API \(title)").onSubmit(connect)
                Button(connecting ? "Connexion…" : connected ? "Remplacer" : "Connecter", action: connect)
                    .disabled(!canConnect)
            }
            .controlSize(.large).disabled(!enabled)
            HStack {
                Link("Obtenir une clé", destination: signupURL)
                Spacer()
                if connected {
                    Button("Retirer la clé", role: .destructive) { Task { await remove() } }
                        .disabled(connecting || store.isLoading)
                }
            }.font(.callout).buttonStyle(.link)
            if let provider { Text(provider.quota).font(.caption).foregroundStyle(.secondary) }
            if !enabled {
                Text("Activez \(title) dans les catalogues.").font(.callout).foregroundStyle(.secondary)
            }
            if let error {
                Text(error).font(.callout).foregroundStyle(.red).textSelection(.enabled)
            }
        }
        .padding(.vertical, SemaTheme.minorSpacing)
        .help("Clé conservée dans le Trousseau de ce Mac, transmise uniquement à \(title).")
        .onDisappear { key = "" }
    }

    private func connect() {
        guard canConnect else { return }
        Task {
            let success = if let provider { await store.connectMarket(provider, key: key) }
                else { await store.connectWebstat(apiKey: key) }
            if success { key = ""; didConnect() }
        }
    }

    private func remove() async {
        if let provider { await store.removeMarketKey(provider) } else { await store.removeWebstatKey() }
    }
}
