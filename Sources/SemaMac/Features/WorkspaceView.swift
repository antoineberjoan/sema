import SwiftUI
import MarketCore

struct WorkspaceView: View {
    @Environment(AppStore.self) private var store
    private var selection: Binding<WorkspaceSection?> {
        Binding(get: { store.section }, set: { if let section = $0 { store.section = section } })
    }

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(spacing: 10) {
                    SemaMark(size: 34)
                    Text("Sema").font(.system(size: 20, weight: .semibold)).tracking(-0.6)
                }
                .padding(.horizontal, 18).padding(.top, 30)
                List(WorkspaceSection.allCases, selection: selection) { section in
                    Label {
                        HStack {
                            Text(section.title)
                            Spacer()
                            if section == .favorites { Text("\(store.favorites.count)").foregroundStyle(.secondary) }
                            if section == .alerts && !store.preferences.alerts.isEmpty { Text("\(store.preferences.alerts.count)").foregroundStyle(.secondary) }
                        }
                    } icon: { Image(systemName: section.symbol).frame(width: 16) }
                    .tag(section)
                    .padding(.vertical, 6)
                }
                .listStyle(.sidebar)
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 9) {
                    Text("VOTRE VEILLE, SIMPLEMENT").font(.system(size: 9, weight: .medium)).tracking(0.8).foregroundStyle(.secondary)
                    SettingsLink {
                        HStack(spacing: 8) { Image(systemName: "person.crop.circle"); Text("Mon espace") }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .help("Ouvrir les réglages de Sema")
                }
                .padding(20)
            }
            .navigationSplitViewColumnWidth(min: 185, ideal: 200, max: 225)
        } detail: {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("VOS REPÈRES, À PORTÉE DE MAIN").font(.system(size: 10, weight: .medium)).tracking(1).foregroundStyle(.secondary)
                        Text(title).font(.system(size: 29, weight: .medium)).tracking(-1)
                    }
                    Spacer()
                    if store.section == .funds || store.section == .alerts {
                        Button { store.isAlertSheetPresented = true } label: { Label("Créer une alerte", systemImage: "bell.badge") }
                    } else {
                        Button { Task { await store.refreshWebstat() } } label: {
                            Label(store.isLoading ? "Actualisation…" : "Actualiser Webstat", systemImage: "arrow.clockwise")
                        }
                        .disabled(store.isLoading || !store.hasWebstatKey)
                        .help(store.hasWebstatKey ? "Actualiser les repères" : "Ajoutez votre clé Webstat dans les réglages")
                    }
                    SettingsLink { Image(systemName: "slider.horizontal.3") }.help("Réglages de Sema")
                }
                .padding(.horizontal, 30).padding(.top, 27).padding(.bottom, 23)

                ScrollView {
                    VStack(alignment: .leading, spacing: 21) {
                        dataStatus
                        switch store.section {
                        case .overview: OverviewView()
                        case .favorites: FavoritesView()
                        case .funds: FundsView()
                        case .alerts: AlertsView()
                        }
                    }
                    .padding(.horizontal, 30).padding(.bottom, 26)
                }
                HStack {
                    Text("Sema · première version")
                    Spacer()
                    Text(store.originSummary)
                }
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .padding(.horizontal, 30).padding(.vertical, 14)
                .background(SemaTheme.background)
            }
            .background(SemaTheme.background)
        }
        .frame(minWidth: 940, minHeight: 700)
        .task { await store.checkWebstatKey() }
        .sheet(isPresented: alertSheetBinding) { AlertEditorView().environment(store) }
        .alert("Sema", isPresented: errorBinding) {
            Button("Compris", role: .cancel) { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
        .overlay(alignment: .topTrailing) {
            if let event = store.simulatedEvent {
                DemoNotificationView(event: event).environment(store).padding(.top, 85).padding(.trailing, 25)
            }
        }
    }

    private var title: String {
        switch store.section {
        case .overview: "Un peu de recul."
        case .favorites: "L’essentiel, choisi par vous."
        case .funds: "Fonds suivis"
        case .alerts: "Mes alertes"
        }
    }

    private var alertSheetBinding: Binding<Bool> {
        Binding(get: { store.isAlertSheetPresented }, set: { store.isAlertSheetPresented = $0 })
    }
    private var errorBinding: Binding<Bool> {
        Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })
    }

    private var dataStatus: some View {
        HStack(spacing: 10) {
            Image(systemName: store.hasLoadedWebstat ? "checkmark.circle" : "info.circle").foregroundStyle(.secondary)
            Text(store.status ?? "Mode démonstration · les valeurs affichées ne sont pas des cours actuels.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if !store.hasWebstatKey {
                SettingsLink { Text("Connecter Webstat") }.font(.system(size: 12))
            }
        }
    }
}
