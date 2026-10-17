// Présente une clé personnelle protégée et le lien officiel pour l’obtenir.
import SwiftUI
import MarketCore

struct MarketConnectionView: View {
    @Environment(AppStore.self) private var store
    let provider: MarketProvider
    @State private var key = ""
    private var connected: Bool { store.connectedMarkets.contains(provider) }
    private var connecting: Bool { store.connectingMarkets.contains(provider) }
    var body: some View {
        VStack(alignment: .leading, spacing: SemaTheme.majorSpacing) {
            if connected {
                Label("Connecté", systemImage: "checkmark.circle.fill").foregroundStyle(store.palette.accent)
            }
            HStack(spacing: SemaTheme.minorSpacing) {
                SecureField(connected ? "Nouvelle clé API" : "Clé API personnelle", text: $key)
                    .textFieldStyle(.roundedBorder).textContentType(.password).privacySensitive()
                    .accessibilityLabel("Clé API \(provider.title)").onSubmit(connect)
                Button(connecting ? "Connexion…" : connected ? "Remplacer" : "Connecter", action: connect)
                    .disabled(connecting || key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }.controlSize(.large).disabled(!store.isSourceEnabled(provider.rawValue))
            HStack {
                Link("Obtenir une clé", destination: provider.signupURL)
                Spacer()
                if connected {
                    Button("Retirer la clé", role: .destructive) { Task { await store.removeMarketKey(provider) } }
                        .disabled(connecting || store.isLoading)
                }
            }.font(.callout).buttonStyle(.link)
            Text(provider.quota).font(.caption).foregroundStyle(.secondary)
            if let error = store.marketErrors[provider] { Text(error).font(.callout).foregroundStyle(.red) }
        }.padding(.vertical, SemaTheme.minorSpacing)
        .task { await store.checkMarketKeys() }.onDisappear { key = "" }
        .help("Clé personnelle conservée dans le Trousseau de ce Mac.")
    }
    private func connect() {
        guard !connecting, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task { if await store.connectMarket(provider, key: key) { key = "" } }
    }
}
