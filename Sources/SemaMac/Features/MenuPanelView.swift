import AppKit
import SwiftUI
import MarketCore

struct MenuPanelView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    @State private var showsFavorites = false
    private var items: [MarketSeries] {
        if showsFavorites { return store.favorites }
        return Array(store.macroSeries.filter { $0.category == .markets }.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                SemaMark(size: 27)
                Text("Sema").font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(store.hasLoadedWebstat ? "Webstat" : "Démo").font(.system(size: 10)).foregroundStyle(.secondary)
                Button {
                    openWorkspace()
                    store.isSearchPresented = true
                } label: { Image(systemName: "magnifyingglass") }
                .buttonStyle(.plain).help("Rechercher un repère · ⌘K").accessibilityLabel("Rechercher un repère")
                SettingsLink { Image(systemName: "slider.horizontal.3") }.buttonStyle(.plain).help("Réglages")
            }
            Picker("Affichage", selection: $showsFavorites) {
                Text("Panorama").tag(false)
                Text("Favoris").tag(true)
            }
            .pickerStyle(.segmented).labelsHidden()
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(items) { item in
                        IndicatorTile(series: item, selected: store.selectedSeriesID == item.id, compact: true) {
                            store.show(item)
                        }
                    }
                }
                if items.isEmpty { Text("Ajoutez vos premiers favoris dans la fenêtre Sema.").font(.system(size: 12)).foregroundStyle(.secondary).padding(20) }
            }
            .frame(height: showsFavorites && items.count > 4 ? 300 : 205)
            HStack {
                Text(store.selectedSeries.name).font(.system(size: 12, weight: .medium))
                Spacer()
                OriginBadge(series: store.selectedSeries)
            }
            HistoryChart(series: store.selectedSeries, period: .month, height: 110)
            HStack {
                Text("Dates et sources dans le détail").font(.system(size: 10)).foregroundStyle(.secondary)
                Spacer()
                Button(action: openWorkspace) { Label("Ouvrir Sema", systemImage: "arrow.up.right") }
                    .buttonStyle(.borderless).font(.system(size: 11))
            }
        }
        .padding(22).frame(width: 450)
        .background(SemaTheme.background)
        .task { await store.checkWebstatKey() }
    }

    private func openWorkspace() {
        openWindow(id: "workspace")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
