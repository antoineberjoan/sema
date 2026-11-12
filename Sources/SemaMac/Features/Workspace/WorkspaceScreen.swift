// Organise Focus et la sidebar persistante ou survolée, avec sélection ordonnée et accès au profil.
import AppKit
import Carbon
import SemaDesign
import SwiftUI
import MarketCore

struct WorkspaceScreen: View {
    private static let searchCorner = DesignRadius.control
    private static let focusHorizontalMargin = DesignSpace.pageInsetWide
    private static let statusPadding = DesignSpace.menuInset
    static let statusSpacing = DesignSpace.fieldGap
    private static let previewInset = DesignSpace.frameInset
    private static let previewVerticalInset = DesignSpace.controlInsetDense
    private static let switcherScrim = DesignColor.scrim
    // Every sidebar text starts on one edge: an 8 pt block inset plus an 8 pt inner padding equals the 16 pt margin.
    private static let sidebarSpacing = DesignSpace.itemGap
    private static let sidebarMargin = DesignSpace.cardInset
    private static let searchSpacing = DesignIcon.gap
    private static let searchPadding = DesignSpace.rowInset
    private static let searchInset = DesignSpace.rowInset
    private static let itemSpacing = DesignSpace.listGapDense
    private static let itemsInset = DesignSpace.rowInset
    private static let rowInsets = EdgeInsets(top: DesignSpace.listGapDense, leading: DesignSpace.rowInset, bottom: DesignSpace.listGapDense, trailing: DesignSpace.rowInset)
    private static let profileSpacing = DesignIcon.gap
    private static let profileTextSpacing = DesignSpace.titleGap
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var sidebarPresentation: SidebarPresentation = .pinned
    @State private var hoveredSidebarZone: SidebarHoverZone?
    @State private var sidebarCloseTask: Task<Void, Never>?
    @State private var removal: MarketSeries?
    @State private var switcherSelection: String?

    var body: some View {
        keyboardWorkspace
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
    }

    private var workspaceLayout: some View {
        NavigationSplitView(columnVisibility: sidebarVisibilityBinding) {
            sidebarContent
                .toolbar(removing: .sidebarToggle)
                .navigationSplitViewColumnWidth(min: DesignLayout.focusMotionSidebarMinWidth, ideal: DesignLayout.focusMotionSidebarWidth, max: DesignLayout.focusMotionSidebarMaxWidth)
        } detail: {
            VStack(spacing: 0) {
                if store.section == .explorer {
                    ExplorerScreen().padding(DesignSpace.pageInsetNarrow).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.section == .overview {
                    ViewThatFits(in: .vertical) {
                        overviewContent
                        ScrollView { overviewContent }
                    }
                } else {
                    ScrollView {
                        Group {
                            switch store.section {
                            case .overview: EmptyView()
                            case .brief: BriefScreen()
                            case .favorites: FavoritesScreen()
                            case .alerts: AlertsScreen()
                            case .explorer: EmptyView()
                            }
                        }
                        .padding(DesignSpace.pageInsetNarrow)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                if store.section != .overview, store.section != .explorer, store.status != nil || store.connectedMarkets.isEmpty {
                    dataStatus.padding(.horizontal, DesignSpace.pageInsetNarrow).padding(.vertical, Self.statusPadding)
                }
            }
            .background(DesignColor.background)
            .navigationTitle(store.section == .overview ? "" : store.section.title)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if store.section == .alerts {
                        Button { store.isAlertSheetPresented = true } label: { Label("Créer une alerte", systemImage: "bell.badge") }
                            .disabled(store.alertableSeries.isEmpty)
                    }
                    if store.isLoading {
                        ProgressView().controlSize(.small).help("Actualisation des repères…")
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbarBackground(.hidden, for: .windowToolbar)
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
                    .frame(width: DesignLayout.focusMotionSidebarWidth)
                    .frame(maxHeight: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignRadius.window, style: .continuous))
                    .elevation(DesignElevation.floating)
                    .padding(.leading, Self.previewInset).padding(.vertical, Self.previewVerticalInset)
                    .onHover { sidebarHover(.panel, inside: $0) }
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(minWidth: DesignLayout.workspaceMinimumWidth, minHeight: DesignLayout.workspaceMinimumHeight)
    }

    private var overviewContent: some View {
        OverviewScreen(isQuickSwitcherShown: columnVisibility == .detailOnly)
            .padding(.horizontal, Self.focusHorizontalMargin).padding(.top, DesignSpace.pageInsetNarrow)
            .padding(.bottom, DesignSpace.pageInsetNarrow)
    }

    private var keyboardWorkspace: some View {
        workspaceLayout
        .background { FocusKeyboard(handle: handleFocusKey).frame(width: 0, height: 0) }
        .overlay {
            if let selection = switcherSelection {
                ZStack {
                    Self.switcherScrim.contentShape(Rectangle()).onTapGesture { closeSwitcher() }
                    FocusSwitcherView(selection: selection) { item in store.show(item); closeSwitcher() }
                        .transition(.opacity)
                }
            }
        }
        .onExitCommand {
            guard store.section == .overview, !store.isSearchPresented, !store.isAlertSheetPresented,
                  !store.isOnboardingPresented, sidebarPresentation != .hidden else { return }
            setSidebarPresentation(.hidden)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { dismissSidebarPreview(); closeSwitcher() }
        }
        .onChange(of: store.isSearchPresented) { _, presented in
            if presented { dismissSidebarPreview(); closeSwitcher() }
        }
        .onChange(of: store.isAlertSheetPresented) { _, presented in
            if presented { dismissSidebarPreview(); closeSwitcher() }
        }
        .onChange(of: store.isOnboardingPresented) { _, presented in
            if presented { closeSwitcher() }
        }
        .onChange(of: store.errorMessage) { _, message in
            if message != nil { closeSwitcher() }
        }
        .onChange(of: store.section) { _, _ in closeSwitcher() }
        .onChange(of: store.followedSeries.map(\.id)) { _, _ in closeSwitcher() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in closeSwitcher() }
    }

    private func handleFocusKey(_ event: NSEvent) -> Bool {
        guard store.section == .overview, !store.isSearchPresented, !store.isAlertSheetPresented,
              !store.isOnboardingPresented, store.errorMessage == nil, removal == nil,
              !store.followedSeries.isEmpty else { return false }
        let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
        if switcherSelection != nil {
            if event.type == .flagsChanged {
                if !modifiers.contains(.command) { commitSwitcher() }
                return false
            }
            if Int(event.keyCode) == kVK_Escape { closeSwitcher(); return true }
            if [kVK_Return, kVK_ANSI_KeypadEnter].contains(Int(event.keyCode)) { commitSwitcher(); return true }
        }
        guard event.type == .keyDown, [kVK_LeftArrow, kVK_RightArrow, kVK_DownArrow, kVK_UpArrow].contains(Int(event.keyCode)),
              modifiers.isEmpty || modifiers == .command else {
            if event.type == .keyDown { closeSwitcher() }
            return false
        }
        let items = store.followedSeries
        let current = items.firstIndex { $0.id == (switcherSelection ?? store.selectedSeries?.id) } ?? 0
        let step = [kVK_RightArrow, kVK_DownArrow].contains(Int(event.keyCode)) ? 1 : -1
        if modifiers == .command || switcherSelection != nil {
            let next = (current + step + items.count) % items.count
            dismissSidebarPreview()
            withAnimation(reduceMotion ? nil : FocusSwitcherMotion.presentation) { switcherSelection = items[next].id }
        } else {
            let next = min(items.count - 1, max(0, current + step))
            store.show(items[next])
        }
        return true
    }

    private func commitSwitcher() {
        if let item = store.followedSeries.first(where: { $0.id == switcherSelection }) { store.show(item) }
        closeSwitcher()
    }

    private func closeSwitcher() {
        guard switcherSelection != nil else { return }
        withAnimation(reduceMotion ? nil : FocusSwitcherMotion.presentation) { switcherSelection = nil }
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
        VStack(alignment: .leading, spacing: Self.sidebarSpacing) {
            Button { store.isSearchPresented = true } label: {
                HStack(spacing: Self.searchSpacing) {
                    Image(systemName: "magnifyingglass")
                    Text("Rechercher")
                    Spacer()
                    Text("⌘K").typeRole(.tag).foregroundStyle(DesignColor.textMuted)
                }
                .typeRole(.small).foregroundStyle(DesignColor.text)
                .padding(Self.searchPadding).background(DesignColor.text.opacity(DesignOpacity.glassRest), in: RoundedRectangle(cornerRadius: Self.searchCorner))
                .contentShape(Rectangle())
            }
            .buttonStyle(PressStyle()).help("Rechercher un repère · ⌘K")
            .padding(.horizontal, Self.searchInset).padding(.top, DesignSpace.rowInset)

            VStack(spacing: Self.itemSpacing) {
                ForEach(WorkspaceSection.allCases.filter { $0 != .overview }) { SidebarItem(section: $0) }
            }
            .padding(.horizontal, Self.itemsInset)

            VStack(spacing: DesignSpace.titleGap) {
                HStack {
                    Text("Mes repères").typeRole(.overline).foregroundStyle(DesignColor.textMuted)
                    Spacer()
                    Button { store.section = .explorer } label: { Image(systemName: "plus") }
                        .buttonStyle(.borderless).help("Ajouter un repère")
                }.padding(.horizontal, Self.sidebarMargin)
                List {
                    ForEach(store.followedSeries) { item in
                        SidebarSeriesRow(series: item)
                            .listRowInsets(Self.rowInsets)
                            .listRowSeparator(.hidden).listRowBackground(Color.clear)
                            .contextMenu {
                                Button(store.isFavorite(item.id) ? "Retirer des favoris" : "Ajouter aux favoris") { store.toggleFavorite(item.id) }
                                Button(store.isWatched(item.id) ? "Ne plus surveiller les mouvements" : "Me prévenir des mouvements inhabituels") {
                                    Task { await store.toggleWatch(item) }
                                }.disabled(!store.canWatch(item))
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

            profileButton.padding(.horizontal, Self.sidebarMargin).padding(.bottom, Self.sidebarMargin)
        }
        .background(DesignColor.surface)
    }

    private var profileButton: some View {
        Button {
            dismissSidebarPreview()
            store.settingsTab = .profile; openSettings()
        } label: {
            HStack(spacing: Self.profileSpacing) {
                ProfileAvatar(profile: store.profile)
                VStack(alignment: .leading, spacing: Self.profileTextSpacing) {
                    if !store.profile.displayName.isEmpty {
                        Text(store.profile.displayName).typeRole(.label)
                            .foregroundStyle(DesignColor.text).lineLimit(1)
                    }
                    Text("Mon espace").typeRole(.small)
                }
                Spacer(minLength: 0)
                Image(systemName: "gearshape").typeRole(.small)
            }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }
        .buttonStyle(.plain).foregroundStyle(DesignColor.text)
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

    private struct DataStatusView: View {
        @Environment(AppStore.self) private var store
        @Environment(\.openSettings) private var openSettings

        var body: some View {
            HStack(spacing: DesignIcon.gap) {
                if let status = store.status {
                    Image(systemName: store.hasLoadedWebstat ? "clock" : "info.circle")
                    Text(status).lineLimit(Int(DesignMeasure.workspaceStatusLines)).help(status)
                }
                Spacer(minLength: WorkspaceScreen.statusSpacing)
                if !store.hasWebstatKey, store.connectedMarkets.isEmpty {
                    Button("Connecter Webstat") { store.settingsTab = .sources; openSettings() }.buttonStyle(.borderless)
                }
            }
            .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
        }
    }

    private var dataStatus: some View {
        DataStatusView()
    }

    private struct SidebarSeriesRow: View {
    private static let textSpacing = DesignSpace.titleGap
    @Environment(AppStore.self) private var store
    let series: MarketSeries
    private var isSelected: Bool { store.section == .overview && store.selectedSeries?.id == series.id }

    var body: some View {
        let displayed = store.displayedSeries(series)
        Button { store.show(series); store.section = .overview } label: {
            VStack(alignment: .leading, spacing: Self.textSpacing) {
                Text(MarketFormat.name(displayed)).typeRole(.small).fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(DesignColor.text).lineLimit(Int(DesignMeasure.nameLines)).multilineTextAlignment(.leading)
                if displayed.latest != nil {
                    Text(MarketFormat.value(displayed)).typeRole(.caption).monospacedDigit().foregroundStyle(DesignColor.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(DesignSpace.rowInset)
            .background(isSelected ? DesignColor.selection(store.palette) : .clear, in: RoundedRectangle(cornerRadius: DesignRadius.control))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(displayed.latest == nil ? MarketFormat.name(displayed) : "\(MarketFormat.name(displayed)), \(MarketFormat.value(displayed))")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct SidebarItem: View {
    private static let iconSpacing = DesignIcon.gap
    private static let countSpacing = DesignSpace.markInset
    private static let verticalPadding = DesignSpace.rowInset
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    let section: WorkspaceSection
    private var isSelected: Bool { store.section == section }

    var body: some View {
        Button { store.section = section } label: {
            HStack(spacing: Self.iconSpacing) {
                Image(systemName: section.symbol).frame(width: DesignLayout.iconWidth)
                Text(section.title)
                Spacer(minLength: Self.countSpacing)
                if section == .favorites { Text("\(store.favorites.count)").foregroundStyle(DesignColor.textMuted) }
                if section == .alerts && !(store.macroAlerts.isEmpty && store.moveWatches.isEmpty) {
                    Text("\(store.macroAlerts.count + store.moveWatches.count)").foregroundStyle(DesignColor.textMuted)
                }
            }
            .typeRole(.small).fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(DesignColor.text)
            .padding(.horizontal, DesignSpace.rowInset).padding(.vertical, Self.verticalPadding)
            .background(isSelected ? DesignColor.selection(store.palette) : (isHovered ? DesignColor.text.opacity(DesignOpacity.glassHover) : .clear),
                        in: RoundedRectangle(cornerRadius: DesignRadius.control, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .timingCurve(DesignEase.hover, duration: DesignDuration.fast), value: isHovered)
    }
}

private enum SidebarPresentation { case pinned, hidden, preview }
private enum SidebarHoverZone { case control, panel }

// Survol de l’icône → aperçu superposé ; sortie de l’icône ET du panneau → fermeture.
// Le délai couvre le passage du pointeur entre la barre d’outils et la sidebar.
private enum FocusMotion {
    static let sidebar = Animation.timingCurve(DesignEase.drawer, duration: DesignDuration.wide)
    static let hoverExitDelay: Duration = .milliseconds(220)
}
}
