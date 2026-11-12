// Cloche « Me prévenir » : un clic surveille les mouvements inhabituels d’un repère, le menu ajoute un seuil.
import SemaDesign
import SwiftUI
import MarketCore

struct WatchButton: View {
    @Environment(AppStore.self) private var store
    let series: MarketSeries

    var body: some View {
        let watched = store.isWatched(series.id)
        Menu {
            Button(watched ? "Ne plus surveiller les mouvements" : "Surveiller les mouvements inhabituels") { toggle() }
            Button("Ajouter un seuil…") { store.prepareAlert(for: series) }
            Divider()
            Button("Voir les alertes") { store.section = .alerts }
        } label: {
            Label(watched ? "Surveillé" : "Me prévenir", systemImage: watched ? "bell.fill" : "bell")
        } primaryAction: { toggle() }
        .menuStyle(.button).buttonStyle(.bordered).controlSize(.small)
        .tint(watched ? DesignColor.accentText(store.palette) : nil)
        .fixedSize()
        .disabled(!store.canWatch(series))
        .help(watched ? "Surveillé : sema vous prévient si ce repère bouge plus que d’habitude."
              : "Être prévenu quand ce repère bouge plus que d’habitude.")
    }

    private func toggle() { Task { await store.toggleWatch(series) } }
}
