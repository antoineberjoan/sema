import SwiftUI
import MarketCore

struct WorkspaceView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 9) {
                    SemaMark(size: 27)
                    Text("Sema").font(.system(size: 19, weight: .semibold)).tracking(-0.5)
                }
                .padding(.horizontal, 20).padding(.top, 22)
                VStack(spacing: 16) {
                    Button { store.isSearchPresented = true } label: {
                        HStack(spacing: 9) {
                            Image(systemName: "magnifyingglass")
                            Text("Rechercher")
                            Spacer()
                            Text("⌘K").font(.system(size: 11))
                        }
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                        .padding(11).background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SemaPressStyle()).help("Rechercher un repère · ⌘K")
                    VStack(spacing: 4) {
                        ForEach(WorkspaceSection.allCases) { SidebarItem(section: $0) }
                    }
                }
                .padding(.horizontal, 12)
                Spacer(minLength: 0)
                SettingsLink {
                    Label("Mon espace", systemImage: "person.crop.circle")
                        .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                }
                .buttonStyle(.plain).font(.system(size: 13)).foregroundStyle(.secondary)
                .help("Ouvrir les réglages de Sema")
                .padding(20)
            }
            .navigationSplitViewColumnWidth(min: 185, ideal: 200, max: 225)
        } detail: {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        switch store.section {
                        case .overview: OverviewView()
                        case .favorites: FavoritesView()
                        case .alerts: AlertsView()
                        case .explorer: ExplorerView()
                        }
                    }
                    .padding(26)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                dataStatus.padding(.horizontal, 26).padding(.vertical, 14)
            }
            .background(SemaTheme.background)
            .navigationTitle(store.section.title)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if store.section == .alerts {
                        Button { store.isAlertSheetPresented = true } label: { Label("Créer une alerte", systemImage: "bell.badge") }
                            .disabled(store.alertableSeries.isEmpty)
                    }
                    Button { Task { await store.refreshWebstat() } } label: {
                        Label(store.isLoading ? "Actualisation…" : "Actualiser Webstat", systemImage: "arrow.clockwise")
                    }
                    .labelStyle(.iconOnly).disabled(store.isLoading || !store.hasWebstatKey)
                    .help(store.hasWebstatKey ? "Actualiser les repères" : "Ajoutez votre clé Webstat dans les réglages")
                    SettingsLink { Label("Réglages", systemImage: "slider.horizontal.3") }
                        .labelStyle(.iconOnly).help("Réglages de Sema")
                }
            }
        }
        .frame(minWidth: 980, minHeight: 680)
        .task { await store.checkWebstatKey() }
        .sheet(isPresented: alertSheetBinding) { AlertEditorView().environment(store) }
        .sheet(isPresented: searchSheetBinding, onDismiss: { store.finishSearch() }) { SeriesSearchView().environment(store) }
        .alert("Sema", isPresented: errorBinding) {
            Button("Compris", role: .cancel) { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
        .overlay(alignment: .topTrailing) {
            if let event = store.simulatedEvent {
                DemoNotificationView(event: event).environment(store).padding(24)
            }
        }
    }

    private var alertSheetBinding: Binding<Bool> {
        Binding(get: { store.isAlertSheetPresented }, set: { store.isAlertSheetPresented = $0 })
    }
    private var searchSheetBinding: Binding<Bool> {
        Binding(get: { store.isSearchPresented }, set: { store.isSearchPresented = $0 })
    }
    private var errorBinding: Binding<Bool> {
        Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })
    }

    private var dataStatus: some View {
        HStack(spacing: 8) {
            Image(systemName: store.hasLoadedWebstat ? "clock" : "info.circle")
            Text(store.status ?? "Démonstration · valeurs fictives")
                .lineLimit(2).help(store.status ?? "Les valeurs de démonstration ne sont pas des cours actuels.")
            Spacer(minLength: 12)
            if !store.hasWebstatKey {
                SettingsLink { Text("Connecter Webstat") }.buttonStyle(.borderless)
            }
        }
        .font(.system(size: 11)).foregroundStyle(.secondary)
    }
}

private struct SidebarItem: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    let section: WorkspaceSection
    private var selected: Bool { store.section == section }

    var body: some View {
        Button { store.section = section } label: {
            HStack(spacing: 10) {
                Image(systemName: section.symbol).frame(width: 17)
                Text(section.title)
                Spacer(minLength: 4)
                if section == .favorites { Text("\(store.favorites.count)").foregroundStyle(.secondary) }
                if section == .alerts && !store.macroAlerts.isEmpty {
                    Text("\(store.macroAlerts.count)").foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 13, weight: selected ? .medium : .regular))
            .foregroundStyle(selected ? Color.primary : .secondary)
            .padding(.horizontal, 12).padding(.vertical, 11)
            .background(Color.primary.opacity(selected ? 0.07 : isHovered ? 0.035 : 0),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(SemaPressStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: isHovered)
    }
}
