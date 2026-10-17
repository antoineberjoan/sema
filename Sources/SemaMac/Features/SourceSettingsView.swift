// Présente les connexions et l’activation des sources sans effacer leurs données en cache.
import SwiftUI
import MarketCore

struct SourceSettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var apiKey = ""

    var body: some View {
        Form {
            Section {
                sourceRow(id: "webstat", title: "Banque de France · Webstat", summary: "Taux, crédit, épargne et statistiques financières.")
                ForEach(StatisticalSource.allCases) { source in
                    sourceRow(id: source.rawValue, title: source.title, summary: summary(source))
                }
            } header: { Text("Catalogues disponibles") } footer: {
                Text("Activez les sources à explorer, puis choisissez vos séries dans Explorer. Seuls les repères suivis sont actualisés. Désactiver une source suspend ses actualisations et ses alertes ; les historiques restent consultables.")
            }
            Section("Connexion Webstat") {
                LabeledContent("Clé personnelle") { Text(store.hasWebstatKey ? "Enregistrée dans le Trousseau" : "À renseigner") }
                SecureField(store.hasWebstatKey ? "Nouvelle clé Webstat" : "Votre clé API Webstat", text: $apiKey)
                    .textContentType(.password).privacySensitive().accessibilityLabel("Clé API Webstat")
                    .disabled(!store.isSourceEnabled("webstat"))
                HStack {
                    Button(store.isLoading ? "Connexion…" : "Enregistrer et connecter") {
                        Task { if await store.connectWebstat(apiKey: apiKey) { apiKey = "" } }
                    }.disabled(store.isLoading || !store.isSourceEnabled("webstat") || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if store.hasWebstatKey {
                        Button("Retirer la clé", role: .destructive) { Task { await store.removeWebstatKey() } }.disabled(store.isLoading)
                    }
                }
                Link("Obtenir une clé sur Webstat", destination: URL(string: "https://webstat.banque-france.fr/login/")!)
                Text("Votre clé reste dans le Trousseau de ce Mac et est transmise uniquement à Webstat. Les autres sources sont accessibles sans clé.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                if let error = store.webstatError { Text(error).font(.system(size: 11)).foregroundStyle(.red) }
            }
        }
        .formStyle(.grouped).onDisappear { apiKey = "" }
    }

    private func sourceRow(id: String, title: String, summary: String) -> some View {
        Toggle(isOn: Binding(get: { store.isSourceEnabled(id) }, set: { store.setSourceEnabled(id, enabled: $0) })) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                Text(summary).font(.system(size: 11)).foregroundStyle(.secondary)
                if store.sourceSeriesCount(id) > 0 {
                    let count = store.sourceSeriesCount(id)
                    Text("\(count) \(count == 1 ? "repère suivi" : "repères suivis")" + (store.isSourceEnabled(id) ? "" : " · en pause"))
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }.padding(.vertical, 5)
        }.toggleStyle(.switch).accessibilityLabel("Activer \(title)")
    }

    private func summary(_ source: StatisticalSource) -> String {
        switch source {
        case .insee: "Loyers, construction, emploi et économie française."
        case .ecb: "Catalogues statistiques de la zone euro."
        case .eurostat: "Comparaisons européennes et données régionales."
        case .bis: "Crédit, dette et système financier international."
        case .oecd: "Immobilier, cycle économique et comparaisons entre pays."
        case .newYorkFed: "Taux monétaires américains et mesures associées."
        case .worldBank: "Indicateurs économiques et structurels mondiaux."
        }
    }
}
