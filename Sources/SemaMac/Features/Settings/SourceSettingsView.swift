// Réunit les sources activables et la connexion Webstat sans modifier les données en cache.
import SwiftUI
import MarketCore

struct SourceSettingsView: View {
    private static let rowPadding: CGFloat = 4
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
            }.padding(.vertical, Self.rowPadding)
        }.toggleStyle(.switch).accessibilityLabel("Activer \(title)")
    }
}
