// Explore les jeux et dimensions des sources publiques pour ajouter un repère précis.
import SwiftUI
import MarketCore

/// Discovery belongs to the source. A starter selection never constrains its catalogue.
struct SourceExplorerView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @State private var sourceID = ""
    var compact = false
    var close: (() -> Void)?
    private var enabledIDs: [String] { (["webstat"] + StatisticalSource.allCases.map(\.rawValue)).filter { store.isSourceEnabled($0) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                if sourceID.isEmpty {
                    Text("Sources").font(.title2.weight(.semibold))
                } else {
                    Button { sourceID = "" } label: { Label("Sources", systemImage: "chevron.left") }
                        .buttonStyle(.borderless)
                    Picker("Source", selection: $sourceID) {
                        ForEach(enabledIDs, id: \.self) { id in Text(store.sourceName(id)).tag(id) }
                    }.labelsHidden().pickerStyle(.menu).frame(width: 190)
                }
                Spacer()
                if sourceID.isEmpty && !enabledIDs.isEmpty {
                    Button { store.settingsTab = .sources; openSettings() } label: {
                        Image(systemName: "slider.horizontal.3")
                    }.buttonStyle(.borderless).help("Gérer les sources").accessibilityLabel("Gérer les sources")
                }
            }
            if enabledIDs.isEmpty {
                ContentUnavailableView {
                    Label("Aucune source active", systemImage: "globe.europe.africa")
                } actions: {
                    Button("Activer une source") { store.settingsTab = .sources; openSettings() }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if sourceID.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: compact ? 240 : 270), spacing: 16)], spacing: 16) {
                        ForEach(enabledIDs, id: \.self) { id in
                            Button { sourceID = id } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(store.sourceName(id)).font(.headline)
                                        Spacer(minLength: 12)
                                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Text(sourceTopics(id)).font(.callout).foregroundStyle(.secondary)
                                        .lineLimit(2).multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
                                .padding(18).foregroundStyle(.primary)
                                .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                                .contentShape(RoundedRectangle(cornerRadius: 14))
                            }.buttonStyle(SemaPressStyle())
                        }
                    }.padding(.bottom, 4)
                }
            } else if let source = StatisticalSource(rawValue: sourceID), store.isSourceEnabled(sourceID) {
                StatisticalExplorerView(source: source, compact: compact, close: close).id(sourceID)
            } else if sourceID == "webstat", store.isSourceEnabled("webstat") { CatalogueBrowserView(compact: compact, close: close) }
        }
        .onChange(of: sourceID) { _, _ in store.closePreview() }
        .onChange(of: enabledIDs, initial: true) { _, ids in
            if !sourceID.isEmpty && !ids.contains(sourceID) { sourceID = ""; store.closePreview() }
        }
    }

    private func sourceTopics(_ id: String) -> String {
        guard let source = StatisticalSource(rawValue: id) else { return "Banque de France · taux et crédit" }
        switch source {
        case .insee: return "Prix, loyers et économie française"
        case .ecb: return "Taux, devises et zone euro"
        case .eurostat: return "Économie et société en Europe"
        case .bis: return "Crédit, banques et immobilier"
        case .oecd: return "Économies et comparaisons internationales"
        case .newYorkFed: return "Taux de référence américains"
        case .worldBank: return "Indicateurs et économies du monde"
        }
    }
}

private struct StatisticalExplorerView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.semaAccent) private var accent
    let source: StatisticalSource
    var compact: Bool
    var close: (() -> Void)?
    @State private var datasets: [StatisticalDataset] = []
    @State private var query = ""
    @State private var visibleCount = 50
    @State private var selectedID: String?
    @State private var keyboardID: String?
    @State private var structure: StatisticalStructure?
    @State private var values: [String: String] = [:]
    @State private var exactKey = ""
    @State private var error: String?
    @State private var loadingCatalogue = false
    @State private var loadingStructure = false
    @State private var choosingDimension: StatisticalDimension?
    @State private var showsDimensions = true
    @State private var showsExactKey = false

    private var matches: [StatisticalDataset] {
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        return datasets.filter { item in words.allSatisfy { (item.title + " " + item.code + " " + item.detail).localizedStandardContains($0) } }
    }
    private var selected: StatisticalDataset? { datasets.first { $0.id == selectedID } }
    private var key: String { exactKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? structure?.key(values: values) ?? "" : exactKey.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canPreview: Bool {
        guard structure != nil, !loadingStructure, !store.isLoadingPreview else { return false }
        return !exactKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || structure?.dimensions.allSatisfy { !(values[$0.id] ?? "").isEmpty } == true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            CatalogueSearchField(query: $query, prompt: "Rechercher dans \(source.title)…",
                isSearching: loadingCatalogue,
                submit: { selectedID = keyboardID ?? matches.first?.id }, move: moveSelection)
            HStack(alignment: .top, spacing: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    if !loadingCatalogue {
                        HStack {
                            Text("\(matches.count.formatted()) \(matches.count == 1 ? "jeu de données" : "jeux de données")")
                            Spacer()
                            Button { Task { await loadCatalogue(reload: true) } } label: { Image(systemName: "arrow.clockwise") }
                                .buttonStyle(.borderless).help("Actualiser le catalogue de la source")
                        }.font(.caption).foregroundStyle(.secondary).padding(.horizontal, 12)
                    }
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(matches.prefix(visibleCount))) { dataset in
                                    Button { keyboardID = dataset.id; selectedID = dataset.id } label: {
                                        VStack(alignment: .leading, spacing: 7) {
                                            Text(dataset.title).font(.system(size: 13, weight: .medium)).lineLimit(3)
                                            Text(dataset.code).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                        }.foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading).padding(12)
                                            .background(keyboardID == dataset.id ? accent.opacity(0.09) : .clear, in: RoundedRectangle(cornerRadius: 11))
                                            .contentShape(Rectangle())
                                    }.buttonStyle(SemaPressStyle()).id(dataset.id)
                                    .accessibilityAddTraits(keyboardID == dataset.id ? .isSelected : [])
                                }
                                if matches.count > visibleCount {
                                    Button("Afficher les jeux suivants") { visibleCount += 50 }.buttonStyle(.borderless).padding(12)
                                }
                                if !loadingCatalogue && matches.isEmpty && error == nil {
                                    ContentUnavailableView("Aucun résultat", systemImage: "magnifyingglass")
                                }
                            }
                        }.onChange(of: keyboardID) { _, id in if let id { proxy.scrollTo(id) } }
                    }
                    if let error, selected == nil {
                        Text(error).font(.system(size: 11)).foregroundStyle(.secondary)
                        Button("Réessayer") { Task { await loadCatalogue() } }.buttonStyle(.borderless)
                    }
                }.frame(minWidth: 230, idealWidth: 280, maxWidth: selected == nil ? .infinity : 310)
                if let selected {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(selected.title).font(.system(size: 17, weight: .semibold)).textSelection(.enabled)
                            if !selected.detail.isEmpty {
                                DisclosureGroup("À propos de ce jeu") {
                                    Text(selected.detail).font(.callout).foregroundStyle(.secondary).textSelection(.enabled).padding(.top, 8)
                                }.font(.callout)
                            }
                            if loadingStructure { ProgressView("Lecture des dimensions…").controlSize(.small) }
                            if let structure {
                                DisclosureGroup("Choisir le repère", isExpanded: $showsDimensions) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(structure.dimensions) { dimension in
                                            HStack(alignment: .firstTextBaseline) {
                                                Text(dimension.title).foregroundStyle(.secondary).frame(maxWidth: 140, alignment: .leading)
                                                Spacer(minLength: 6)
                                                if dimension.codes.count == 1, let code = dimension.codes.first {
                                                    Text(code.title).multilineTextAlignment(.trailing)
                                                } else if dimension.codes.isEmpty {
                                                    TextField(dimension.id, text: Binding(get: { values[dimension.id] ?? "" }, set: { values[dimension.id] = $0; store.closePreview() }))
                                                        .textFieldStyle(.roundedBorder).accessibilityLabel(dimension.title)
                                                } else {
                                                    Button { choosingDimension = dimension } label: {
                                                        HStack(spacing: 6) {
                                                            Text(dimension.codes.first { $0.id == values[dimension.id] }?.title ?? "Choisir…").lineLimit(2).multilineTextAlignment(.trailing)
                                                            Image(systemName: "chevron.up.chevron.down").font(.system(size: 8))
                                                        }
                                                    }.buttonStyle(.borderless).accessibilityLabel("\(dimension.title) : \(values[dimension.id] ?? "à choisir")")
                                                }
                                            }
                                        }
                                        DisclosureGroup("Code exact", isExpanded: $showsExactKey) {
                                            TextField(source == .newYorkFed ? "Nom de la mesure" : source == .worldBank ? "Code du pays" : "Clé SDMX", text: $exactKey)
                                                .textFieldStyle(.roundedBorder).font(.system(.callout, design: .monospaced))
                                                .accessibilityLabel("Clé exacte du repère").padding(.top, 8)
                                        }.foregroundStyle(.secondary)
                                    }.padding(.top, 14)
                                }.font(.callout).padding(16).background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                                Button { store.openStatisticalPreview(dataset: selected, structure: structure, key: key); showsDimensions = false } label: {
                                    Label("Afficher le repère", systemImage: "chart.xyaxis.line")
                                }.buttonStyle(.bordered).disabled(!canPreview)
                            }
                            if store.isLoadingPreview { ProgressView("Chargement de l’historique…").controlSize(.small) }
                            if let value = store.previewSeries, value.statisticalDescriptor?.dataset.id == selected.id {
                                SeriesDetailView(series: value, preview: true)
                                HStack {
                                    if let existing = store.followedMatch(for: value) {
                                        Label("Déjà suivi via \(existing.originBadge)", systemImage: "checkmark").font(.system(size: 11)).foregroundStyle(.secondary)
                                        Spacer()
                                        if existing.id != value.id {
                                            Button("Utiliser cette source") { _ = store.usePreviewSource() }.buttonStyle(.borderless)
                                        }
                                        Button("Ouvrir") { store.show(existing); store.section = .overview; store.closePreview(); close?() }
                                            .buttonStyle(.borderedProminent).disabled(store.previewRequiresRefresh)
                                    } else {
                                        Button("Ajouter à mes repères") { _ = store.followStatisticalPreview() }.buttonStyle(.borderedProminent)
                                            .disabled(store.isLoadingPreview || store.previewError != nil)
                                    }
                                }
                            }
                            if let error {
                                Label(error, systemImage: "exclamationmark.triangle").font(.system(size: 11)).foregroundStyle(.secondary)
                                if structure == nil { Button("Réessayer la lecture") { Task { await loadStructure() } }.buttonStyle(.borderless) }
                            }
                            if let error = store.previewError { Label(error, systemImage: "exclamationmark.triangle").font(.system(size: 11)).foregroundStyle(.secondary) }
                            if store.previewRequiresRefresh {
                                Button("Actualiser mes repères") { Task { await store.refreshSeries() } }.buttonStyle(.borderless).disabled(store.isLoading)
                            }
                        }.padding(.trailing, 4).padding(.bottom, 16)
                    }.frame(minWidth: compact ? 340 : 350, maxWidth: .infinity)
                }
            }
        }
        .task { await loadCatalogue() }
        .task(id: selectedID) { await loadStructure() }
        .onChange(of: query) { _, _ in visibleCount = 50; keyboardID = matches.first?.id }
        .onChange(of: exactKey) { _, _ in store.closePreview() }
        .onDisappear { store.closePreview() }
        .sheet(item: $choosingDimension) { dimension in
            StatisticalCodePicker(dimension: dimension, selected: values[dimension.id]) { code in
                values[dimension.id] = code; exactKey = ""; store.closePreview()
            }
        }
    }
    private func loadCatalogue(reload: Bool = false) async {
        loadingCatalogue = true; error = nil
        defer { loadingCatalogue = false }
        do {
            datasets = try await store.statisticalDatasets(source: source, reload: reload)
            try Task.checkCancellation(); keyboardID = matches.first?.id
        } catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }
    private func loadStructure() async {
        store.closePreview(); structure = nil; values = [:]; exactKey = ""; error = nil; showsDimensions = true; showsExactKey = false; loadingStructure = false
        guard let selected else { return }
        let id = selected.id; loadingStructure = true
        defer { if selectedID == id { loadingStructure = false } }
        do {
            let value = try await StatisticalClient().structure(dataset: selected)
            try Task.checkCancellation(); guard selectedID == id else { return }
            structure = value
            // A dimension with one published choice is unambiguous; all others remain the user's choice.
            values = Dictionary(value.dimensions.compactMap { $0.codes.count == 1 ? ($0.id, $0.codes[0].id) : nil }, uniquingKeysWith: { _, new in new })
        } catch is CancellationError { }
        catch { if selectedID == id { self.error = error.localizedDescription } }
    }
    private func moveSelection(_ offset: Int) {
        let items = matches; guard !items.isEmpty else { return }
        let index = items.firstIndex { $0.id == keyboardID } ?? 0
        let next = min(max(index + offset, 0), items.count - 1)
        visibleCount = max(visibleCount, next + 1); keyboardID = items[next].id
    }
}

private struct StatisticalCodePicker: View {
    @Environment(\.dismiss) private var dismiss
    let dimension: StatisticalDimension
    let selected: String?
    let choose: (String) -> Void
    @State private var query = ""
    @FocusState private var searchFocused: Bool
    private var codes: [StatisticalCode] { dimension.codes.filter { query.isEmpty || ($0.title + " " + $0.id).localizedStandardContains(query) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(dimension.title).font(.headline)
            TextField("Rechercher une valeur ou un code…", text: $query).textFieldStyle(.roundedBorder).focused($searchFocused)
                .onSubmit { if codes.count == 1, let code = codes.first { choose(code.id); dismiss() } }
            List(codes) { code in
                Button { choose(code.id); dismiss() } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) { Text(code.title); Text(code.id).font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        if selected == code.id { Image(systemName: "checkmark") }
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain).padding(.vertical, 4)
            }.listStyle(.plain)
            HStack { Text("\(codes.count.formatted()) \(codes.count == 1 ? "valeur" : "valeurs")").font(.caption).foregroundStyle(.secondary); Spacer(); Button("Fermer") { dismiss() }.keyboardShortcut(.cancelAction) }
        }.padding(22).frame(width: 490, height: 470).onAppear { searchFocused = true }
    }
}
