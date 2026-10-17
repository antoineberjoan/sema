// Permet de chercher et prévisualiser les séries Webstat avant de les ajouter à sa sélection.
import SwiftUI
import MarketCore

struct ExplorerView: View {
    var body: some View { SourceExplorerView().frame(minHeight: 510) }
}

/// Shared by Explorer and ⌘K. Result rows stay in place while the detail loads.
struct CatalogueBrowserView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @Environment(\.semaAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let selectionDuration = 0.14
    private let previewDuration = 0.22
    @State private var showsFilters = false
    @State private var selectedID: String?
    @State private var isAdding = false
    @FocusState private var searchFocused: Bool
    var compact = false
    var close: (() -> Void)?

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Titre, thème ou code Webstat…", text: $store.catalogueSearch.query)
                    .textFieldStyle(.plain).font(.system(size: 16)).focused($searchFocused)
                    .accessibilityLabel("Rechercher dans le catalogue Webstat")
                    .onSubmit(openSelection)
                    .onKeyPress(.downArrow) { moveSelection(1); return .handled }
                    .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
                if store.isSearchingCatalogue { ProgressView().controlSize(.small) }
                Button { showsFilters.toggle() } label: { Label("Filtres", systemImage: "line.3.horizontal.decrease") }
                    .buttonStyle(.borderless).font(.system(size: 12))
            }.padding(.horizontal, 4)
            if showsFilters || hasFilters {
                HStack(alignment: .top, spacing: 14) {
                    Picker("Jeu", selection: $store.catalogueSearch.datasetID) {
                        Text("Tous les jeux").tag("")
                        ForEach(store.catalogueDatasets) { Text($0.title).tag($0.id) }
                    }.frame(maxWidth: .infinity)
                    Picker("Zone", selection: $store.catalogueSearch.area) {
                        Text("Toutes les zones").tag("")
                        ForEach(areas, id: \.key) { Text($0.value).tag($0.key) }
                    }.frame(maxWidth: .infinity)
                    Picker("Fréquence", selection: $store.catalogueSearch.frequency) {
                        Text("Toutes").tag("")
                        ForEach(frequencies, id: \.key) { Text($0.value).tag($0.key) }
                    }.frame(maxWidth: .infinity)
                    if hasFilters {
                        Button { store.catalogueSearch.datasetID = ""; store.catalogueSearch.area = ""; store.catalogueSearch.frequency = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }.buttonStyle(.plain).help("Retirer les filtres").padding(.top, 4)
                    }
                }.font(.system(size: 11))
            }
            if !store.hasWebstatKey {
                ContentUnavailableView {
                    Label("Tout Webstat, à portée de main.", systemImage: "globe.europe.africa")
                } description: {
                    Text("Connectez votre clé personnelle pour explorer les jeux de données. Vos repères déjà enregistrés restent consultables.")
                } actions: { Button("Connecter Webstat") { store.settingsTab = .sources; openSettings() }.buttonStyle(.borderedProminent) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .top, spacing: 20) {
                    results.frame(minWidth: compact ? 260 : 300, maxWidth: store.previewDescriptor == nil ? .infinity : 350)
                    if let descriptor = store.previewDescriptor {
                        previewPane(descriptor)
                            .frame(minWidth: compact ? 330 : 360, maxWidth: .infinity)
                            .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : 6)))
                    }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: previewDuration), value: store.previewDescriptor?.key)
            }
        }
        .onAppear { store.searchCatalogue(); searchFocused = true }
         .onChange(of: store.catalogueSearch) { old, new in
            if old.datasetID != new.datasetID { store.catalogueSearch.area = "" }
            store.searchCatalogue(); selectedID = nil
        }
        .onChange(of: store.catalogueResults.map(\.key)) { _, ids in
            if selectedID == nil || !ids.contains(selectedID!) { selectedID = ids.first }
        }
        .onChange(of: store.hasWebstatKey) { _, connected in if connected { store.searchCatalogue() } }
        .onDisappear { store.cancelCatalogueSearch() }
    }

    private func previewPane(_ descriptor: WebstatSeriesDescriptor) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Aperçu").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                if store.isLoadingPreview { ProgressView().controlSize(.mini) }
                Spacer()
                Button { store.closePreview() } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain).help("Fermer l’aperçu").accessibilityLabel("Fermer l’aperçu")
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if store.isLoadingPreview && store.previewSeries == nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(descriptor.title).font(.system(size: 18, weight: .semibold))
                            Text(descriptor.definition).font(.system(size: 12)).foregroundStyle(.secondary)
                            ProgressView("Chargement de l’historique…").controlSize(.small)
                        }.frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading).padding(20)
                    } else {
                        SeriesDetailView(series: store.previewSeries ?? descriptor.series(observations: []), preview: true)
                    }
                    if let error = store.previewError {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                        if store.previewRequiresRefresh {
                            Button("Actualiser mes repères") { Task { await store.refreshSeries() } }
                                .buttonStyle(.borderless).disabled(store.isLoading)
                        } else {
                            Button("Réessayer") { store.openPreview(descriptor) }.buttonStyle(.borderless)
                        }
                    }
                }.padding(.bottom, 10)
            }
            HStack {
                if let existing = store.followedMatch(for: store.previewSeries ?? descriptor.series(observations: [])) {
                    Label("Déjà suivi via \(existing.originBadge)", systemImage: "checkmark").foregroundStyle(accent)
                    Spacer()
                    if let value = store.previewSeries, existing.id != value.id {
                        Button("Utiliser cette source") { _ = store.usePreviewSource() }.buttonStyle(.borderless)
                    }
                    Button("Ouvrir le repère") {
                        store.show(existing); store.section = .overview; store.closePreview(); close?()
                    }.buttonStyle(.borderedProminent).disabled(store.previewRequiresRefresh)
                } else {
                    Button {
                        isAdding = true
                        Task { _ = await store.follow(descriptor); isAdding = false }
                    } label: {
                        if isAdding { ProgressView().controlSize(.small) }
                        else { Label("Ajouter à mes repères", systemImage: "plus") }
                    }.buttonStyle(.borderedProminent).disabled(isAdding || store.isLoadingPreview || store.previewSeries == nil)
                    Spacer(minLength: 0)
                }
            }.font(.system(size: 12)).padding(.horizontal, 4)
        }
    }

    private var results: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(store.isSearchingCatalogue && store.catalogueResults.isEmpty ? "Recherche…" : "\(store.catalogueTotal.formatted()) \(store.catalogueTotal == 1 ? "série" : "séries")")
                        Spacer()
                        Text("Webstat")
                    }.font(.system(size: 10)).foregroundStyle(.secondary).padding(.horizontal, 12).padding(.bottom, 8)
                    ForEach(store.catalogueResults) { item in
                        Button { selectedID = item.id; store.openPreview(item) } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(item.title).font(.system(size: 12, weight: .medium)).lineLimit(3)
                                    Spacer(minLength: 0)
                                    if store.followedMatch(for: item.series(observations: [])) != nil { Image(systemName: "checkmark").foregroundStyle(accent).accessibilityLabel("Déjà suivi") }
                                }
                                Text([item.area, item.frequencyTitle, item.displayUnit].compactMap { $0 }.joined(separator: " · "))
                                    .font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(2)
                                Text(item.datasetID).font(.system(size: 9)).foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading).padding(12)
                            .background(selectedID == item.id ? accent.opacity(0.09) : .clear, in: RoundedRectangle(cornerRadius: 11))
                            .contentShape(Rectangle())
                        }.buttonStyle(SemaPressStyle()).id(item.id)
                        .accessibilityAddTraits(selectedID == item.id ? .isSelected : [])
                        .help(item.definition)
                        .animation(reduceMotion ? nil : .easeOut(duration: selectionDuration), value: selectedID == item.id)
                    }
                    if let error = store.catalogueError {
                        Label(error, systemImage: "exclamationmark.triangle").font(.system(size: 12)).foregroundStyle(.secondary).padding(16)
                        Button("Réessayer") { store.searchCatalogue() }.buttonStyle(.borderless).padding(.horizontal, 16)
                    } else if !store.isSearchingCatalogue && store.catalogueResults.isEmpty {
                        ContentUnavailableView("Aucun repère trouvé", systemImage: "magnifyingglass",
                            description: Text("Essayez un autre terme, un code exact ou retirez un filtre."))
                    }
                    if store.canLoadMoreCatalogue {
                        Button("Afficher les résultats suivants") { store.searchCatalogue(loadMore: true) }
                            .buttonStyle(.borderless).padding(16).frame(maxWidth: .infinity)
                    }
                }
            }
            .onChange(of: selectedID) { _, id in if let id { proxy.scrollTo(id) } }
        }
    }
    private var hasFilters: Bool { !store.catalogueSearch.datasetID.isEmpty || !store.catalogueSearch.area.isEmpty || !store.catalogueSearch.frequency.isEmpty }
    private var areas: [(key: String, value: String)] { (store.catalogueLabels[store.catalogueDatasets.first { $0.id == store.catalogueSearch.datasetID }?.areaCodelist ?? "CL_AREA"] ?? [:]).sorted { $0.value.localizedStandardCompare($1.value) == .orderedAscending } }
    private var frequencies: [(key: String, value: String)] {
        let labels = store.catalogueLabels["CL_FREQ"] ?? ["D": "Quotidien", "B": "Jours ouvrés", "W": "Hebdomadaire", "M": "Mensuel", "Q": "Trimestriel", "H": "Semestriel", "A": "Annuel"]
        return labels.sorted { $0.key < $1.key }
    }
    private func moveSelection(_ offset: Int) {
        let items = store.catalogueResults
        guard !items.isEmpty else { return }
        let index = items.firstIndex { $0.id == selectedID } ?? 0
        selectedID = items[min(max(index + offset, 0), items.count - 1)].id
    }
    private func openSelection() {
        if let item = store.catalogueResults.first(where: { $0.id == selectedID }) { store.openPreview(item) }
    }
}
