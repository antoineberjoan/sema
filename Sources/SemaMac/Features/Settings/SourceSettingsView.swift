// Réunit les sources activables et leurs clés personnelles sans modifier les données en cache.
import SemaDesign
import SwiftUI
import MarketCore

struct SourceSettingsView: View {
    private static let rowPadding = DesignSpace.markInset
    @Environment(AppStore.self) private var store

    var body: some View {
        Form {
            Section("Webstat") { SourceKeyView(source: "webstat") }
            ForEach(MarketProvider.allCases) { provider in
                Section(provider.title) { SourceKeyView(source: provider.rawValue) }
            }
            Section("FRED · Fed de Saint-Louis") { SourceKeyView(source: StatisticalSource.fred.rawValue) }
            Section("Catalogues") {
                sourceRow(id: "webstat", title: "Banque de France · Webstat")
                ForEach(MarketProvider.allCases) { provider in
                    sourceRow(id: provider.rawValue, title: provider.title)
                }
                ForEach(StatisticalSource.allCases) { source in
                    sourceRow(id: source.rawValue, title: source.title)
                }
            }
            .help("Désactiver une source met ses alertes en pause et conserve ses historiques.")
            Section {
                ForEach(CentralBankFeed.allCases) { feed in sourceRow(id: feed.rawValue, title: feed.title) }
            } header: { Text("Communiqués des banques centrales") } footer: {
                Text("Flux publics, sans clé. Ils servent au contexte d’un mouvement et au brief du matin.").typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
            Section {
                Picker("Source des titres", selection: Binding(get: { store.headlineSource }, set: { store.setHeadlineSource($0) })) {
                    ForEach(HeadlineSource.allCases) { Text($0.title).tag($0) }
                }
            } header: { Text("Titres d’actualité") } footer: {
                Text("Les titres restent des liens vers leurs éditeurs. Alpha Vantage utilise la clé déjà connectée et un appel de son quota quotidien. Conditions d’usage de GDELT à vérifier avant une diffusion large.")
                    .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
            Section {
                Picker("Rédacteur", selection: Binding(get: { store.summaryWriter }, set: { store.setSummaryWriter($0) })) {
                    ForEach(SummaryWriter.allCases) { Text($0.title).tag($0) }
                }
                if store.summaryWriter == .appleIntelligence, !store.isAppleIntelligenceAvailable {
                    Text(AppleSummaryWriter.UnavailableError().errorDescription ?? "").typeRole(.small).foregroundStyle(DesignColor.textMuted)
                }
                if store.summaryWriter == .claude { SourceKeyView(source: AppStore.claudeSourceID) }
            } header: { Text("Synthèse rédigée") } footer: {
                Text("Désactivée par défaut. Apple Intelligence rédige sur ce Mac, sans réseau. Claude reçoit seulement les faits numérotés de la séance (repères, variations, titres), jamais votre profil ni vos autres clés. Une phrase n’est affichée que si ses chiffres et son sens se retrouvent dans les faits qu’elle cite.")
                    .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
        }
        .formStyle(.grouped)
        .task { await store.checkMarketKeys() }
    }

    private func sourceRow(id: String, title: String) -> some View {
        Toggle(isOn: Binding(get: { store.isSourceEnabled(id) }, set: { store.setSourceEnabled(id, enabled: $0) })) {
            HStack {
                Text(title)
                Spacer()
            }.padding(.vertical, Self.rowPadding)
        }.toggleStyle(.switch).accessibilityLabel("Activer \(title)")
    }
}
