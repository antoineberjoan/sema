// Présente le catalogue Webstat et la prévisualisation d’une série avant son ajout, depuis Explorer comme depuis ⌘K.
import SwiftUI
import MarketCore

/// Shared by Explorer and ⌘K. Result rows stay in place while the detail loads.
struct CatalogueBrowserView: View {
    private static let titleFont = Font.system(size: 18, weight: .semibold)
    private static let sectionSpacing: CGFloat = 16
    private static let textInset: CGFloat = 4
    private static let filterSpacing: CGFloat = 14
    private static let toolbarSpacing: CGFloat = 12
    private static let clearButtonTopPadding: CGFloat = 4
    private static let columnSpacing: CGFloat = 20
    private static let compactResultsMinWidth: CGFloat = 260
    private static let resultsMinWidth: CGFloat = 300
    private static let resultsMaxWidth: CGFloat = 350
    private static let compactPreviewMinWidth: CGFloat = 330
    private static let previewMinWidth: CGFloat = 360
    private static let previewOffset: CGFloat = 6
    private static let previewSpacing: CGFloat = 14
    private static let previewContentSpacing: CGFloat = 16
    private static let loadingMinHeight: CGFloat = 280
    private static let loadingPadding: CGFloat = 20
    private static let previewBottomPadding: CGFloat = 10
    private static let detailLines = 2
    private static let messagePadding: CGFloat = 16
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @Environment(\.semaAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let selectionDuration = 0.14
    private let previewDuration = 0.22
    @State private var showsFilters = false
    @State private var selectedID: String?
    @State private var isAdding = false
    var compact = false
    var close: (() -> Void)?

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: Self.sectionSpacing) {
            if !store.hasWebstatKey {
                HStack(spacing: Self.sectionSpacing) {
                    Label("Clé personnelle requise", systemImage: "key").foregroundStyle(.secondary)
                    Spacer()
                    Button("Connecter Webstat") { store.settingsTab = .sources; openSettings() }
                        .buttonStyle(.borderedProminent).tint(store.palette.controlAccent)
                }.padding(SemaTheme.majorSpacing).background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: SemaTheme.cardCorner))
                Spacer(minLength: 0)
            } else {
                HStack(spacing: Self.toolbarSpacing) {
                    CatalogueSearchField(query: $store.catalogueSearch.query, prompt: "Rechercher dans Webstat…",
                        isSearching: store.isSearchingCatalogue, submit: openSelection, move: moveSelection)
                    Button { showsFilters.toggle() } label: {
                        Label("Filtres", systemImage: hasFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
                    }.buttonStyle(.borderless).help("Filtrer les résultats")
                        .accessibilityValue(showsFilters ? "Ouverts" : "Fermés")
                }
                if showsFilters {
                    HStack(alignment: .top, spacing: Self.filterSpacing) {
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
                            }.buttonStyle(.plain).help("Retirer les filtres").padding(.top, Self.clearButtonTopPadding)
                        }
                    }.font(.callout)
                }
                HStack(alignment: .top, spacing: Self.columnSpacing) {
                    results.frame(minWidth: compact ? Self.compactResultsMinWidth : Self.resultsMinWidth, maxWidth: store.previewDescriptor == nil ? .infinity : Self.resultsMaxWidth)
                    if let descriptor = store.previewDescriptor {
                        previewPane(descriptor)
                            .frame(minWidth: compact ? Self.compactPreviewMinWidth : Self.previewMinWidth, maxWidth: .infinity)
                            .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : Self.previewOffset)))
                    }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: previewDuration), value: store.previewDescriptor?.key)
            }
        }
        .onAppear { store.searchCatalogue() }
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
        VStack(alignment: .leading, spacing: Self.previewSpacing) {
            HStack {
                Text("Aperçu").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                if store.isLoadingPreview { ProgressView().controlSize(.mini) }
                Spacer()
                Button { store.closePreview() } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain).help("Fermer l’aperçu").accessibilityLabel("Fermer l’aperçu")
            }
            ScrollView {
                VStack(alignment: .leading, spacing: Self.previewContentSpacing) {
                    if store.isLoadingPreview && store.previewSeries == nil {
                        VStack(alignment: .leading, spacing: Self.previewContentSpacing) {
                            Text(descriptor.title).font(Self.titleFont)
                            Text(descriptor.definition).font(.callout).foregroundStyle(.secondary)
                            ProgressView("Chargement de l’historique…").controlSize(.small)
                        }.frame(maxWidth: .infinity, minHeight: Self.loadingMinHeight, alignment: .topLeading).padding(Self.loadingPadding)
                    } else {
                        SeriesDetailView(series: store.previewSeries ?? descriptor.series(observations: []), preview: true)
                    }
                    if let error = store.previewError {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.subheadline).foregroundStyle(.secondary)
                        if store.previewRequiresRefresh {
                            Button("Actualiser mes repères") { Task { await store.refreshSeries() } }
                                .buttonStyle(.borderless).disabled(store.isLoading)
                        } else {
                            Button("Réessayer") { store.openPreview(descriptor) }.buttonStyle(.borderless)
                        }
                    }
                }.padding(.bottom, Self.previewBottomPadding)
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
            }.font(.callout).padding(.horizontal, Self.textInset)
        }
    }

    private var results: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: SemaTheme.rowSpacing) {
                    HStack {
                        Text(store.isSearchingCatalogue && store.catalogueResults.isEmpty ? "Recherche…" : "\(store.catalogueTotal.formatted()) \(store.catalogueTotal == 1 ? "série" : "séries")")
                        Spacer()
                    }.font(.caption).foregroundStyle(.secondary).padding(.horizontal, SemaTheme.rowPadding).padding(.bottom, SemaTheme.minorSpacing)
                    ForEach(store.catalogueResults) { item in
                        Button { selectedID = item.id; store.openPreview(item) } label: {
                            VStack(alignment: .leading, spacing: SemaTheme.rowTextSpacing) {
                                HStack(alignment: .top, spacing: SemaTheme.minorSpacing) {
                                    Text(MarketFormat.name(item.series(observations: []))).font(.callout.weight(.medium)).lineLimit(SemaTheme.rowTitleLines)
                                    Spacer(minLength: 0)
                                    if store.followedMatch(for: item.series(observations: [])) != nil { Image(systemName: "checkmark").foregroundStyle(accent).accessibilityLabel("Déjà suivi") }
                                }
                                Text([item.area, item.frequencyTitle, item.displayUnit].compactMap { $0 }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(Self.detailLines)
                            }
                            .foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading).padding(SemaTheme.rowPadding)
                            .background(selectedID == item.id ? accent.opacity(SemaTheme.selectionOpacity) : .clear, in: RoundedRectangle(cornerRadius: SemaTheme.rowCorner))
                            .contentShape(Rectangle())
                        }.buttonStyle(SemaPressStyle()).id(item.id)
                        .accessibilityAddTraits(selectedID == item.id ? .isSelected : [])
                        .help(item.definition)
                        .animation(reduceMotion ? nil : .easeOut(duration: selectionDuration), value: selectedID == item.id)
                    }
                    if let error = store.catalogueError {
                        Label(error, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.secondary).padding(Self.messagePadding)
                        Button("Réessayer") { store.searchCatalogue() }.buttonStyle(.borderless).padding(.horizontal, Self.messagePadding)
                    } else if !store.isSearchingCatalogue && store.catalogueResults.isEmpty {
                        ContentUnavailableView("Aucun résultat", systemImage: "magnifyingglass")
                    }
                    if store.canLoadMoreCatalogue {
                        Button("Afficher les résultats suivants") { store.searchCatalogue(loadMore: true) }
                            .buttonStyle(.borderless).padding(Self.messagePadding).frame(maxWidth: .infinity)
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
