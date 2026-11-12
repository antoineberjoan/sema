// Saisit, remplace ou retire la clé personnelle d’une source, dans les réglages comme à la première connexion.
import SemaDesign
import SwiftUI
import MarketCore

struct SourceKeyView: View {
    @Environment(AppStore.self) private var store
    @State private var key = ""
    let source: String
    var didConnect: () -> Void = {}

    private static let fredSignupURL = URL(string: "https://fredaccount.stlouisfed.org/apikeys")!
    private static let claudeSignupURL = URL(string: "https://console.anthropic.com/settings/keys")!
    private var provider: MarketProvider? { MarketProvider(rawValue: source) }
    private var isFRED: Bool { source == StatisticalSource.fred.rawValue }
    private var isClaude: Bool { source == AppStore.claudeSourceID }
    private var title: String { isClaude ? "Claude" : isFRED ? StatisticalSource.fred.title : provider?.title ?? "Webstat" }
    private var signupURL: URL { isClaude ? Self.claudeSignupURL : isFRED ? Self.fredSignupURL : provider?.signupURL ?? WebstatSite.loginURL }
    private var isConnected: Bool {
        isClaude ? store.hasClaudeKey : isFRED ? store.hasFREDKey : provider.map { store.connectedMarkets.contains($0) } ?? store.hasWebstatKey
    }
    private var isConnecting: Bool {
        isClaude ? store.isConnectingClaude : isFRED ? store.isConnectingFRED : provider.map { store.connectingMarkets.contains($0) } ?? store.isLoading
    }
    private var error: String? {
        isClaude ? store.claudeError : isFRED ? store.fredError : provider.map { store.marketErrors[$0] } ?? store.webstatError
    }
    private var isEnabled: Bool { store.isSourceEnabled(source) }
    private var canConnect: Bool { !isConnecting && isEnabled && !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpace.groupGap) {
            if isConnected {
                Label("Connecté", systemImage: "checkmark.circle.fill").foregroundStyle(DesignColor.accentText(store.palette))
            }
            HStack(spacing: DesignSpace.fieldGap) {
                SecureField(isConnected ? "Nouvelle clé API" : "Clé API personnelle", text: $key)
                    .textFieldStyle(.roundedBorder).textContentType(.password).privacySensitive()
                    .accessibilityLabel("Clé API \(title)").onSubmit(connect)
                Button(isConnecting ? "Connexion…" : isConnected ? "Remplacer" : "Connecter", action: connect)
                    .disabled(!canConnect)
            }
            .controlSize(.large).disabled(!isEnabled)
            HStack {
                Link("Obtenir une clé", destination: signupURL)
                Spacer()
                if isConnected {
                    Button("Retirer la clé", role: .destructive) { Task { await remove() } }
                        .disabled(isConnecting || store.isLoading)
                }
            }.typeRole(.small).buttonStyle(.link)
            if let provider { Text(provider.quota).typeRole(.micro).foregroundStyle(DesignColor.textMuted) }
            if isFRED {
                Text("Gratuite · VIX, taux américains quotidiens, dollar et calendrier des publications.")
                    .typeRole(.micro).foregroundStyle(DesignColor.textMuted)
            }
            if isClaude {
                Text("Payante à l’usage sur votre compte Anthropic · quelques centimes par synthèse.")
                    .typeRole(.micro).foregroundStyle(DesignColor.textMuted)
            }
            if !isEnabled {
                Text("Activez \(title) dans les catalogues.").typeRole(.small).foregroundStyle(DesignColor.textMuted)
            }
            if let error {
                Text(error).typeRole(.small).foregroundStyle(DesignColor.danger).textSelection(.enabled)
            }
        }
        .padding(.vertical, DesignSpace.rowInset)
        .help("Clé conservée dans le Trousseau de ce Mac, transmise uniquement à \(title).")
        .onDisappear { key = "" }
    }

    private func connect() {
        guard canConnect else { return }
        Task {
            let success = if isClaude { await store.connectClaude(key: key) }
                else if isFRED { await store.connectFRED(key: key) }
                else if let provider { await store.connectMarket(provider, key: key) }
                else { await store.connectWebstat(apiKey: key) }
            if success { key = ""; didConnect() }
        }
    }

    private func remove() async {
        if isClaude { await store.removeClaudeKey() }
        else if isFRED { await store.removeFREDKey() }
        else if let provider { await store.removeMarketKey(provider) } else { await store.removeWebstatKey() }
    }
}
