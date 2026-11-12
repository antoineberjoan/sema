// Présente le catalogue Webstat et la prévisualisation d’une série avant son ajout, depuis Explorer comme depuis ⌘K.
import SemaDesign
import SwiftUI
import MarketCore

/// Shared by Explorer and ⌘K. Result rows stay in place while the detail loads.
struct CatalogueBrowserView: View {
    private static let sectionSpacing = DesignSpace.itemGap
    private static let textInset = DesignSpace.markInset
    private static let filterSpacing = DesignSpace.fieldGap
    private static let toolbarSpacing = DesignSpace.fieldGap
    private static let clearButtonTopPadding = DesignSpace.markInset
    private static let columnSpacing = DesignSpace.groupGap
    private static let compactResultsMinWidth: CGFloat = 260
    private static let resultsMinWidth: CGFloat = 300
    private static let resultsMaxWidth: CGFloat = 350
    private static let compactPreviewMinWidth: CGFloat = 330
    private static let previewMinWidth: CGFloat = 360
    private static let previewOffset = DesignMotion.shift
    private static let previewSpacing = DesignSpace.fieldGap
    private static let previewContentSpacing = DesignSpace.itemGap
    private static let loadingMinHeight: CGFloat = 280
    private static let loadingPadding = DesignSpace.pageInsetNarrow
    private static let previewBottomPadding = DesignSpace.frameInset
    private static let detailLines = 2
    private static let messagePadding = DesignSpace.cardInset
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @Environment(\.palette) private var palette
    private var accentText: Color { DesignColor.accentText(palette) }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let selectionDuration = DesignDuration.fast
    private let previewDuration = DesignDuration.standard
    @State private var isFiltersShown = false
    @State private var selectedID: String?
    @State private var isAdding = false
    var isCompact = false
    var close: (() -> Void)?

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: Self.sectionSpacing) {
            if !store.hasWebstatKey {
                HStack(spacing: Self.sectionSpacing) {
                    Label("Clé personnelle requise", systemImage: "key").foregroundStyle(DesignColor.textMuted)
                    Spacer()
                    Button("Connecter Webstat") { store.settingsTab = .sources; openSettings() }
                        .buttonStyle(.borderedProminent).tint(DesignColor.accentControl(store.palette))
                }.padding(DesignSpace.cardInset).background(DesignColor.surface, in: RoundedRectangle(cornerRadius: DesignRadius.block))
                Spacer(minLength: 0)
            } else {
                HStack(spacing: Self.toolbarSpacing) {
                    CatalogueSearchField(query: $store.catalogueSearch.query, prompt: "Rechercher dans Webstat…",
                        isSearching: store.isSearchingCatalogue, submit: openSelection, move: moveSelection)
                    Button { isFiltersShown.toggle() } label: {
                        Label("Filtres", systemImage: hasFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
                    }.buttonStyle(.borderless).help("Filtrer les résultats")
                        .accessibilityValue(isFiltersShown ? "Ouverts" : "Fermés")
                }
                if isFiltersShown {
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
                                Image(systemName: "xmark.circle.fill").foregroundStyle(DesignColor.textMuted)
                            }.buttonStyle(.plain).help("Retirer les filtres").padding(.top, Self.clearButtonTopPadding)
                        }
                    }.typeRole(.small)
                }
                HStack(alignment: .top, spacing: Self.columnSpacing) {
                    results.frame(minWidth: isCompact ? Self.compactResultsMinWidth : Self.resultsMinWidth, maxWidth: store.previewDescriptor == nil ? .infinity : Self.resultsMaxWidth)
                    if let descriptor = store.previewDescriptor {
                        previewPane(descriptor)
                            .frame(minWidth: isCompact ? Self.compactPreviewMinWidth : Self.previewMinWidth, maxWidth: .infinity)
                            .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : Self.previewOffset)))
                    }
                }
                .animation(reduceMotion ? nil : Animation.timingCurve(DesignEase.out, duration: previewDuration), value: store.previewDescriptor?.key)
            }
        }
        .onAppear { store.searchCatalogue() }
        .onChange(of: store.catalogueSearch) { previous, current in
            if previous.datasetID != current.datasetID { store.catalogueSearch.area = "" }
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
                Text("Aperçu").typeRole(.overline).foregroundStyle(DesignColor.textMuted)
                if store.isLoadingPreview { ProgressView().controlSize(.mini) }
                Spacer()
                Button { store.closePreview() } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain).help("Fermer l’aperçu").accessibilityLabel("Fermer l’aperçu")
            }
            ScrollView {
                VStack(alignment: .leading, spacing: Self.previewContentSpacing) {
                    if store.isLoadingPreview && store.previewSeries == nil {
                        VStack(alignment: .leading, spacing: Self.previewContentSpacing) {
                            Text(descriptor.title).typeRole(.section)
                            Text(descriptor.definition).typeRole(.small).foregroundStyle(DesignColor.textMuted)
                            ProgressView("Chargement de l’historique…").controlSize(.small)
                        }.frame(maxWidth: .infinity, minHeight: Self.loadingMinHeight, alignment: .topLeading).padding(Self.loadingPadding)
                    } else {
                        SeriesDetailView(series: store.previewSeries ?? descriptor.series(observations: []), preview: true)
                    }
                    if let error = store.previewError {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                        if store.isPreviewRefreshRequired {
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
                    Label("Déjà suivi via \(existing.originBadge)", systemImage: "checkmark").foregroundStyle(accentText)
                    Spacer()
                    if let value = store.previewSeries, existing.id != value.id {
                        Button("Utiliser cette source") { _ = store.usePreviewSource() }.buttonStyle(.borderless)
                    }
                    Button("Ouvrir le repère") {
                        store.show(existing); store.section = .overview; store.closePreview(); close?()
                    }.buttonStyle(.borderedProminent).disabled(store.isPreviewRefreshRequired)
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
            }.typeRole(.small).padding(.horizontal, Self.textInset)
        }
    }

    private var results: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignSpace.listGapDense) {
                    HStack {
                        Text(store.isSearchingCatalogue && store.catalogueResults.isEmpty ? "Recherche…" : "\(store.catalogueTotal.formatted()) \(store.catalogueTotal == 1 ? "série" : "séries")")
                        Spacer()
                    }.typeRole(.micro).foregroundStyle(DesignColor.textMuted).padding(.horizontal, DesignSpace.rowInset).padding(.bottom, DesignSpace.fieldGap)
                    ForEach(store.catalogueResults) { item in
                        Button { selectedID = item.id; store.openPreview(item) } label: {
                            VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                                HStack(alignment: .top, spacing: DesignSpace.fieldGap) {
                                    Text(MarketFormat.name(item.series(observations: []))).typeRole(.label).lineLimit(ExplorerLayout.rowTitleLines)
                                    Spacer(minLength: 0)
                                    if store.followedMatch(for: item.series(observations: [])) != nil { Image(systemName: "checkmark").foregroundStyle(accentText).accessibilityLabel("Déjà suivi") }
                                }
                                Text([item.area, item.frequencyTitle, item.displayUnit].compactMap { $0 }.joined(separator: " · "))
                                    .typeRole(.micro).foregroundStyle(DesignColor.textMuted).lineLimit(Self.detailLines)
                            }
                            .foregroundStyle(DesignColor.text).frame(maxWidth: .infinity, alignment: .leading).padding(DesignSpace.rowInset)
                            .background(selectedID == item.id ? DesignColor.selection(palette) : .clear, in: RoundedRectangle(cornerRadius: DesignRadius.block))
                            .contentShape(Rectangle())
                        }.buttonStyle(PressStyle()).id(item.id)
                        .accessibilityAddTraits(selectedID == item.id ? [.isSelected] : [])
                        .help(item.definition)
                        .animation(reduceMotion ? nil : .timingCurve(DesignEase.inOut, duration: selectionDuration), value: selectedID == item.id)
                    }
                    if let error = store.catalogueError {
                        Label(error, systemImage: "exclamationmark.triangle").typeRole(.small).foregroundStyle(DesignColor.textMuted).padding(Self.messagePadding)
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
