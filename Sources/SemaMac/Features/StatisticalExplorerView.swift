// Explore les jeux et dimensions des sources publiques pour ajouter un repère précis.
import SwiftUI
import MarketCore

/// Discovery belongs to the source. A starter selection never constrains its catalogue.
struct SourceExplorerView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @State private var sourceID = "webstat"
    var compact = false
    var close: (() -> Void)?
    private var enabledIDs: [String] { (["webstat"] + StatisticalSource.allCases.map(\.rawValue)).filter { store.isSourceEnabled($0) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                if !enabledIDs.isEmpty { Picker("Source", selection: $sourceID) {
                    ForEach(enabledIDs, id: \.self) { id in Text(store.sourceName(id)).tag(id) }
                }.pickerStyle(.menu).frame(maxWidth: 300) }
                Spacer()
                if !enabledIDs.isEmpty, sourceID != "webstat" {
                    Label("Accès public · sans clé", systemImage: "network")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Button { store.settingsTab = .sources; openSettings() } label: {
                    Label("Gérer les sources", systemImage: "slider.horizontal.3")
                }.buttonStyle(.borderless).font(.system(size: 11))
            }
            if enabledIDs.isEmpty {
                ContentUnavailableView("Choisissez vos sources", systemImage: "globe.europe.africa",
                    description: Text("Activez un catalogue dans les réglages pour explorer ses repères. Les historiques enregistrés restent disponibles."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let source = StatisticalSource(rawValue: sourceID), store.isSourceEnabled(sourceID) {
                StatisticalExplorerView(source: source, compact: compact, close: close).id(sourceID)
            } else if sourceID == "webstat", store.isSourceEnabled("webstat") { CatalogueBrowserView(compact: compact, close: close) }
        }
        .onChange(of: sourceID) { _, _ in store.closePreview() }
        .onChange(of: enabledIDs, initial: true) { _, ids in
            if !ids.contains(sourceID) { sourceID = ids.first ?? ""; store.closePreview() }
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
    @FocusState private var searchFocused: Bool

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
        HStack(alignment: .top, spacing: 22) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Rechercher un jeu de données…", text: $query)
                        .textFieldStyle(.plain).focused($searchFocused)
                        .accessibilityLabel("Rechercher dans le catalogue \(source.title)")
                        .onSubmit { selectedID = keyboardID ?? matches.first?.id }
                        .onKeyPress(.downArrow) { moveSelection(1); return .handled }
                        .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
                }.font(.system(size: 13)).padding(.horizontal, 10)
                if loadingCatalogue {
                    ProgressView("Chargement du catalogue…").controlSize(.small).padding(10)
                } else {
                    HStack {
                        Text("\(matches.count.formatted()) \(matches.count == 1 ? "jeu de données" : "jeux de données")")
                        Spacer()
                        Button { Task { await loadCatalogue(reload: true) } } label: { Image(systemName: "arrow.clockwise") }
                            .buttonStyle(.borderless).help("Actualiser le catalogue de la source")
                    }.font(.system(size: 10)).foregroundStyle(.secondary).padding(.horizontal, 10)
                }
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(matches.prefix(visibleCount))) { dataset in
                                Button { keyboardID = dataset.id; selectedID = dataset.id } label: {
                                    VStack(alignment: .leading, spacing: 7) {
                                        Text(dataset.title).font(.system(size: 12, weight: .medium)).lineLimit(3)
                                        Text(dataset.code).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                                    }.foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading).padding(12)
                                        .background(keyboardID == dataset.id ? accent.opacity(0.09) : .clear, in: RoundedRectangle(cornerRadius: 11))
                                        .contentShape(Rectangle())
                                }.buttonStyle(SemaPressStyle()).id(dataset.id)
                                .accessibilityAddTraits(keyboardID == dataset.id ? .isSelected : [])
                            }
                            if matches.count > visibleCount {
                                Button("Afficher les jeux suivants") { visibleCount += 50 }.buttonStyle(.borderless).padding(12)
                            }
                            if !loadingCatalogue && matches.isEmpty {
                                ContentUnavailableView("Aucun jeu trouvé", systemImage: "magnifyingglass", description: Text("Essayez un autre titre ou le code du jeu."))
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
                        if !selected.detail.isEmpty { Text(selected.detail).font(.system(size: 11)).foregroundStyle(.secondary).textSelection(.enabled) }
                        if loadingStructure { ProgressView("Lecture des dimensions…").controlSize(.small) }
                        if let structure {
                            DisclosureGroup("Définir le repère", isExpanded: $showsDimensions) {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(structure.dimensions) { dimension in
                                        HStack(alignment: .firstTextBaseline) {
                                            Text(dimension.title).font(.system(size: 11)).foregroundStyle(.secondary).frame(maxWidth: 140, alignment: .leading)
                                            Spacer(minLength: 6)
                                            if dimension.codes.isEmpty {
                                                TextField(dimension.id, text: Binding(get: { values[dimension.id] ?? "" }, set: { values[dimension.id] = $0; store.closePreview() }))
                                                    .textFieldStyle(.roundedBorder).font(.system(size: 11))
                                            } else {
                                                Button { choosingDimension = dimension } label: {
                                                    HStack(spacing: 6) {
                                                        Text(dimension.codes.first { $0.id == values[dimension.id] }?.title ?? "Choisir…").lineLimit(2).multilineTextAlignment(.trailing)
                                                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 8))
                                                    }
                                                }.buttonStyle(.borderless).font(.system(size: 11)).accessibilityLabel("\(dimension.title) : \(values[dimension.id] ?? "à choisir")")
                                            }
                                        }
                                    }
                                    TextField(source == .newYorkFed ? "Ou nom exact de la mesure" : source == .worldBank ? "Ou code exact du pays" : "Ou clé SDMX exacte", text: $exactKey)
                                        .textFieldStyle(.roundedBorder).font(.system(size: 11, design: .monospaced))
                                        .accessibilityLabel("Clé exacte du repère")
                                    Text("Les dimensions viennent de la source. Une combinaison inexistante peut ne renvoyer aucune observation.")
                                        .font(.system(size: 10)).foregroundStyle(.secondary)
                                }.padding(.top, 12)
                            }.font(.system(size: 12))
                            Button { store.openStatisticalPreview(dataset: selected, structure: structure, key: key); showsDimensions = false } label: {
                                Label("Prévisualiser", systemImage: "chart.xyaxis.line")
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
                        Text(source.scope).font(.system(size: 10)).foregroundStyle(.secondary)
                    }.padding(.trailing, 4).padding(.bottom, 16)
                }.frame(minWidth: compact ? 340 : 350, maxWidth: .infinity)
            }
        }
        .task { await loadCatalogue(); searchFocused = true }
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
        store.closePreview(); structure = nil; values = [:]; exactKey = ""; error = nil; showsDimensions = true; loadingStructure = false
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
            HStack { Text("\(codes.count.formatted()) valeurs").font(.caption).foregroundStyle(.secondary); Spacer(); Button("Fermer") { dismiss() }.keyboardShortcut(.cancelAction) }
        }.padding(22).frame(width: 490, height: 470).onAppear { searchFocused = true }
    }
}
