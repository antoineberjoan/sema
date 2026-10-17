import SwiftUI
import MarketCore

struct WorkspaceView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var sidebarPresentation: SidebarPresentation = .pinned
    @State private var hoveredSidebarZone: SidebarHoverZone?
    @State private var sidebarCloseTask: Task<Void, Never>?
    @State private var removal: MarketSeries?

    var body: some View {
        NavigationSplitView(columnVisibility: sidebarVisibilityBinding) {
            sidebarContent
                .toolbar(removing: .sidebarToggle)
                .navigationSplitViewColumnWidth(min: 220, ideal: FocusMotion.sidebarWidth, max: 280)
        } detail: {
            VStack(spacing: 0) {
                if store.section == .explorer {
                    ExplorerView().padding(26).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        Group {
                            switch store.section {
                            case .overview: OverviewView(showsQuickSwitcher: columnVisibility == .detailOnly)
                            case .favorites: FavoritesView()
                            case .alerts: AlertsView()
                            case .explorer: EmptyView()
                            }
                        }
                        .padding(.horizontal, store.section == .overview ? 48 : 26)
                        .padding(.top, store.section == .overview ? 36 : 26)
                        .padding(.bottom, 26)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                if store.section != .overview {
                    dataStatus.padding(.horizontal, 26).padding(.vertical, 14)
                }
            }
            .background(SemaTheme.background)
            .navigationTitle(store.section == .overview ? "sema" : store.section.title)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if store.section == .alerts {
                        Button { store.isAlertSheetPresented = true } label: { Label("Créer une alerte", systemImage: "bell.badge") }
                            .disabled(store.alertableSeries.isEmpty)
                    }
                    if store.isLoading {
                        ProgressView().controlSize(.small).help("Actualisation des repères…")
                    }
                    SettingsLink { Label("Réglages", systemImage: "gearshape") }
                        .labelStyle(.iconOnly).help("Réglages de sema · ⌘,")
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    setSidebarPresentation(sidebarPresentation == .pinned ? .hidden : .pinned)
                } label: { Label("Barre latérale", systemImage: "sidebar.left") }
                .labelStyle(.iconOnly)
                .help("Survolez pour un aperçu ; cliquez pour ouvrir ou fermer la barre latérale.")
                .accessibilityLabel(sidebarPresentation == .pinned ? "Fermer la barre latérale" : "Garder la barre latérale ouverte")
                .onHover { sidebarHover(.control, inside: $0) }
            }
        }
        .overlay(alignment: .topLeading) {
            if sidebarPresentation == .preview {
                sidebarContent
                    .frame(width: FocusMotion.sidebarWidth)
                    .frame(maxHeight: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 14, x: 4, y: 6)
                    .padding(.leading, 10).padding(.vertical, 6)
                    .onHover { sidebarHover(.panel, inside: $0) }
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(minWidth: 980, minHeight: 680)
        .onExitCommand {
            guard store.section == .overview, !store.isSearchPresented, !store.isAlertSheetPresented,
                  !store.isOnboardingPresented, sidebarPresentation != .hidden else { return }
            setSidebarPresentation(.hidden)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { dismissSidebarPreview() }
        }
        .onChange(of: store.isSearchPresented) { _, presented in
            if presented { dismissSidebarPreview() }
        }
        .onChange(of: store.isAlertSheetPresented) { _, presented in
            if presented { dismissSidebarPreview() }
        }
        .onDisappear { sidebarCloseTask?.cancel() }
        .task { await store.checkWebstatKey() }
        .sheet(isPresented: alertSheetBinding) { AlertEditorView().environment(store) }
        .sheet(isPresented: searchSheetBinding, onDismiss: { store.finishSearch() }) { SeriesSearchView().environment(store) }
        .alert("sema", isPresented: errorBinding) {
            Button("Compris", role: .cancel) { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
        .confirmationDialog("Retirer ce repère ?", isPresented: Binding(get: { removal != nil }, set: { if !$0 { removal = nil } }), titleVisibility: .visible) {
            Button("Retirer de mes repères", role: .destructive) { if let removal { _ = store.unfollow(removal.id) }; removal = nil }
            Button("Annuler", role: .cancel) { removal = nil }
        } message: {
            Text("Ses alertes seront conservées et mises en pause. Son historique restera en cache.")
        }
        .overlay(alignment: .topTrailing) {
            if let event = store.simulatedEvent {
                DemoNotificationView(event: event).environment(store).padding(24)
            }
        }
    }

    private var columnVisibility: NavigationSplitViewVisibility {
        sidebarPresentation == .pinned ? .all : .detailOnly
    }

    private var sidebarVisibilityBinding: Binding<NavigationSplitViewVisibility> {
        Binding(get: { columnVisibility }, set: { visibility in
            guard visibility != columnVisibility else { return }
            setSidebarPresentation(visibility == .detailOnly ? .hidden : .pinned)
        })
    }

    private func setSidebarPresentation(_ presentation: SidebarPresentation) {
        sidebarCloseTask?.cancel()
        withAnimation(reduceMotion ? nil : FocusMotion.sidebar) { sidebarPresentation = presentation }
    }

    private func dismissSidebarPreview() {
        hoveredSidebarZone = nil
        sidebarCloseTask?.cancel()
        if sidebarPresentation == .preview { setSidebarPresentation(.hidden) }
    }

    private func sidebarHover(_ zone: SidebarHoverZone, inside: Bool) {
        if inside {
            hoveredSidebarZone = zone
            sidebarCloseTask?.cancel()
            if sidebarPresentation == .hidden { setSidebarPresentation(.preview) }
        } else if hoveredSidebarZone == zone {
            hoveredSidebarZone = nil
            guard sidebarPresentation == .preview else { return }
            sidebarCloseTask?.cancel()
            sidebarCloseTask = Task { @MainActor in
                do { try await Task.sleep(for: FocusMotion.hoverExitDelay) } catch { return }
                guard !Task.isCancelled, hoveredSidebarZone == nil, sidebarPresentation == .preview else { return }
                setSidebarPresentation(.hidden)
            }
        }
    }

    private var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button { store.isSearchPresented = true } label: {
                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass")
                    Text("Rechercher")
                    Spacer()
                    Text("⌘K").font(.system(size: 11)).foregroundStyle(SemaTheme.sidebarSecondaryText)
                }
                .font(.system(size: 12)).foregroundStyle(.primary)
                .padding(11).background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
                .contentShape(Rectangle())
            }
            .buttonStyle(SemaPressStyle()).help("Rechercher un repère · ⌘K")
            .padding(.horizontal, 14).padding(.top, 20)

            VStack(spacing: 2) {
                ForEach(WorkspaceSection.allCases.filter { $0 != .overview }) { SidebarItem(section: $0) }
            }
            .padding(.horizontal, 10)

            VStack(spacing: 8) {
                HStack {
                    Text("Mes repères").font(.system(size: 11, weight: .medium)).foregroundStyle(SemaTheme.sidebarSecondaryText)
                    Spacer()
                    Button { store.section = .explorer } label: { Image(systemName: "plus") }
                        .buttonStyle(.borderless).help("Ajouter un repère")
                }.padding(.horizontal, 22)
                List {
                    ForEach(store.followedSeries) { item in
                        SidebarSeriesRow(series: item)
                            .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))
                            .listRowSeparator(.hidden).listRowBackground(Color.clear)
                            .contextMenu {
                                Button(store.isFavorite(item.id) ? "Retirer des favoris" : "Ajouter aux favoris") { store.toggleFavorite(item.id) }
                                Divider()
                                Button("Monter") { store.moveFollowed(item.id, by: -1) }
                                Button("Descendre") { store.moveFollowed(item.id, by: 1) }
                                Divider()
                                Button("Retirer de mes repères", role: .destructive) { removal = item }
                            }
                    }
                    .onMove { store.moveFollowed(from: $0, to: $1) }
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
            }
            .frame(maxHeight: .infinity)

            profileButton.padding(.horizontal, 22).padding(.bottom, 22)
        }
    }

    private var profileButton: some View {
        Button {
            dismissSidebarPreview()
            store.settingsTab = .profile; openSettings()
        } label: {
            HStack(spacing: 10) {
                ProfileAvatar(profile: store.profile)
                VStack(alignment: .leading, spacing: 3) {
                    if !store.profile.displayName.isEmpty {
                        Text(store.profile.displayName).font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary).lineLimit(1)
                    }
                    Text("Mon espace").font(.system(size: store.profile.displayName.isEmpty ? 13 : 11))
                }
                Spacer(minLength: 0)
                Image(systemName: "gearshape").font(.system(size: 12))
            }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }
        .buttonStyle(.plain).foregroundStyle(.primary)
        .help("Personnaliser mon profil local")
        .accessibilityLabel(store.profile.displayName.isEmpty ? "Mon espace" : "Mon espace, \(store.profile.displayName)")
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
                Button("Connecter Webstat") { store.settingsTab = .sources; openSettings() }.buttonStyle(.borderless)
            }
        }
        .font(.system(size: 11)).foregroundStyle(.secondary)
    }
}

private struct SidebarSeriesRow: View {
    @Environment(AppStore.self) private var store
    let series: MarketSeries
    private var selected: Bool { store.section == .overview && store.selectedSeries?.id == series.id }

    var body: some View {
        let displayed = store.displayedSeries(series)
        Button { store.show(series); store.section = .overview } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(displayed.name).font(.system(size: 12, weight: selected ? .medium : .regular))
                    .foregroundStyle(.primary).lineLimit(2).multilineTextAlignment(.leading)
                Text(MarketFormat.value(displayed)).font(.system(size: 11)).monospacedDigit().foregroundStyle(SemaTheme.sidebarSecondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(12)
            .background(selected ? SemaTheme.sidebarSelection : .clear, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(SemaPressStyle())
        .accessibilityLabel("\(displayed.name), \(MarketFormat.value(displayed))\(series.isDemo ? ", données fictives" : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
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
                if section == .favorites { Text("\(store.favorites.count)").foregroundStyle(SemaTheme.sidebarSecondaryText) }
                if section == .alerts && !store.macroAlerts.isEmpty {
                    Text("\(store.macroAlerts.count)").foregroundStyle(SemaTheme.sidebarSecondaryText)
                }
            }
            .font(.system(size: 13, weight: selected ? .medium : .regular))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(selected ? SemaTheme.sidebarSelection : Color.primary.opacity(isHovered ? 0.035 : 0),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(SemaPressStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: isHovered)
    }
}

private enum SidebarPresentation { case pinned, hidden, preview }
private enum SidebarHoverZone { case control, panel }

// Survol de l’icône → aperçu superposé ; sortie de l’icône ET du panneau → fermeture.
// Le délai couvre le passage du pointeur entre la barre d’outils et la sidebar.
private enum FocusMotion {
    static let sidebarWidth: CGFloat = 232
    static let sidebar = Animation.snappy(duration: 0.24, extraBounce: 0)
    static let hoverExitDelay: Duration = .milliseconds(220)
}
