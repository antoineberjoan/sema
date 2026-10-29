// Explore les jeux et dimensions des sources publiques pour ajouter un repère précis.
import SwiftUI
import MarketCore

/// Discovery belongs to the source. A starter selection never constrains its catalogue.
struct SourceExplorerView: View {
    private static let pickerWidth: CGFloat = 190
    private static let compactCardMinWidth: CGFloat = 240
    private static let cardMinWidth: CGFloat = 270
    private static let cardMinHeight: CGFloat = 66
    private static let topicLines = 2
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @State private var sourceID = ""
    var compact = false
    var close: (() -> Void)?
    private var enabledIDs: [String] { (["webstat"] + MarketProvider.allCases.map(\.rawValue) + StatisticalSource.allCases.map(\.rawValue)).filter { store.isSourceEnabled($0) } }
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.majorSpacing) {
            HStack {
                if sourceID.isEmpty {
                    Text("Sources").font(.title2.weight(.semibold))
                } else {
                    Button { sourceID = "" } label: { Label("Sources", systemImage: "chevron.left") }
                        .buttonStyle(.borderless)
                    Picker("Source", selection: $sourceID) {
                        ForEach(enabledIDs, id: \.self) { id in Text(store.sourceName(id)).tag(id) }
                    }.labelsHidden().pickerStyle(.menu).frame(width: Self.pickerWidth)
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
            } else if let provider = MarketProvider(rawValue: sourceID), store.isSourceEnabled(sourceID) {
                MarketExplorerView(provider: provider, close: close).id(sourceID)
            } else if sourceID.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: compact ? Self.compactCardMinWidth : Self.cardMinWidth), spacing: Theme.majorSpacing)], spacing: Theme.majorSpacing) {
                        ForEach(enabledIDs, id: \.self) { id in
                            Button { sourceID = id } label: {
                                VStack(alignment: .leading, spacing: Theme.minorSpacing) {
                                    HStack {
                                        Text(store.sourceName(id)).font(.headline)
                                        Spacer(minLength: Theme.rowPadding)
                                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Text(sourceTopics(id)).font(.callout).foregroundStyle(.secondary)
                                        .lineLimit(Self.topicLines).multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, minHeight: Self.cardMinHeight, alignment: .leading)
                                .padding(Theme.majorSpacing).foregroundStyle(.primary)
                                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCorner))
                                .contentShape(RoundedRectangle(cornerRadius: Theme.cardCorner))
                            }.buttonStyle(PressStyle())
                        }
                    }.padding(.bottom, Theme.rowSpacing)
                }
            } else if let source = StatisticalSource(rawValue: sourceID), store.isSourceEnabled(sourceID) {
                StatisticalExplorerView(source: source, compact: compact, close: close).id(sourceID)
            } else if sourceID == "webstat", store.isSourceEnabled("webstat") { CatalogueBrowserView(compact: compact, close: close) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: sourceID) { _, _ in store.closePreview() }
        .onChange(of: enabledIDs, initial: true) { _, ids in
            if !sourceID.isEmpty && !ids.contains(sourceID) { sourceID = ""; store.closePreview() }
        }
    }

    private func sourceTopics(_ id: String) -> String {
        if let provider = MarketProvider(rawValue: id) { return provider.quota }
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
    private static let datasetsMinWidth: CGFloat = 230
    private static let datasetsIdealWidth: CGFloat = 280
    private static let datasetsMaxWidth: CGFloat = 310
    private static let compactSeriesMinWidth: CGFloat = 340
    private static let seriesMinWidth: CGFloat = 350
    private static let advancedLabelMaxWidth: CGFloat = 140
    private static let advancedMaxHeight: CGFloat = 250
    private static let formSpacing: CGFloat = 12
    private static let seriesTitleLines = 4
    private static let valueLines = 2
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
    @State private var catalogueSeries: [StatisticalSeriesDescriptor] = []
    @State private var seriesQuery = ""
    @State private var seriesError: String?
    @State private var visibleSeriesCount = 50
    @State private var keyboardSeriesKey: String?
    @State private var selectedSeriesKey: String?
    @State private var pendingStarter: StatisticalStarter?
    @State private var starterError: String?
    @State private var showsAdvanced = false

    private var availableStarters: [StatisticalStarter] {
        StatisticalStarter.recommendations(for: source).filter { starter in datasets.contains(where: starter.matches) }
    }
    private var matches: [StatisticalDataset] {
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        return datasets.filter { item in words.allSatisfy { (item.title + " " + item.code + " " + item.detail).localizedStandardContains($0) } }
    }
    private var seriesMatches: [StatisticalSeriesDescriptor] {
        let words = seriesQuery.split(whereSeparator: \.isWhitespace).map(String.init)
        return catalogueSeries.filter { item in
            let text = [item.title, item.key, item.fields["IDBANK"], item.labels["REF_AREA"], item.fields["REF_AREA"]].compactMap { $0 }.joined(separator: " ")
            return words.allSatisfy { text.localizedStandardContains($0) }
        }
    }
    private var selected: StatisticalDataset? { datasets.first { $0.id == selectedID } }
    private var key: String { exactKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? structure?.key(values: values) ?? "" : exactKey.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canPreview: Bool {
        guard structure != nil, !loadingStructure, !store.isLoadingPreview else { return false }
        return !exactKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || structure?.dimensions.allSatisfy { !(values[$0.id] ?? "").isEmpty } == true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.majorSpacing) {
            CatalogueSearchField(query: $query, prompt: "Rechercher dans \(source.title)…", isSearching: loadingCatalogue,
                submit: { selectedID = keyboardID ?? matches.first?.id }, move: moveSelection)
            HStack(alignment: .top, spacing: Theme.majorSpacing) {
                datasetsList.frame(minWidth: Self.datasetsMinWidth, idealWidth: Self.datasetsIdealWidth, maxWidth: selected == nil ? .infinity : Self.datasetsMaxWidth)
                if let selected {
                    if selectedSeriesKey != nil {
                        previewPane.frame(minWidth: compact ? Self.compactSeriesMinWidth : Self.seriesMinWidth, maxWidth: .infinity)
                    } else {
                        seriesList(selected).frame(minWidth: compact ? Self.compactSeriesMinWidth : Self.seriesMinWidth, maxWidth: .infinity)
                    }
                }
            }
        }
        .task { await loadCatalogue() }
        .task(id: selectedID) { await loadSeriesCatalogue() }
        .onChange(of: query) { _, _ in visibleCount = 50; keyboardID = matches.first?.id }
        .onChange(of: seriesQuery) { _, _ in visibleSeriesCount = 50; keyboardSeriesKey = seriesMatches.first?.key }
        .onDisappear { store.closePreview() }
        .sheet(item: $choosingDimension) { dimension in
            StatisticalCodePicker(dimension: dimension, selected: values[dimension.id]) { code in values[dimension.id] = code; exactKey = "" }
        }
    }

    private var datasetsList: some View {
        VStack(alignment: .leading, spacing: Theme.majorSpacing) {
            if !loadingCatalogue {
                HStack {
                    Text("\(matches.count.formatted()) \(matches.count == 1 ? "jeu de données" : "jeux de données")")
                    Spacer()
                    Button { Task { await loadCatalogue(reload: true) } } label: { Image(systemName: "arrow.clockwise") }
                        .buttonStyle(.borderless).help("Actualiser le catalogue de la source")
                }.font(.caption).foregroundStyle(.secondary).padding(.horizontal, Theme.rowPadding)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Theme.rowSpacing) {
                        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !availableStarters.isEmpty {
                            Text("Pour commencer").font(.caption.weight(.semibold)).foregroundStyle(.secondary).padding(.horizontal, Theme.rowPadding)
                            ForEach(availableStarters) { starter in
                                starterRow(starter)
                            }
                            Divider().padding(.horizontal, Theme.rowPadding)
                        }
                        Text("Catalogue").font(.caption.weight(.semibold)).foregroundStyle(.secondary).padding(.horizontal, Theme.rowPadding)
                        ForEach(Array(matches.prefix(visibleCount))) { dataset in
                            Button { pendingStarter = nil; starterError = nil; keyboardID = dataset.id; selectedID = dataset.id } label: {
                                VStack(alignment: .leading, spacing: Theme.rowTextSpacing) {
                                    Text(dataset.title).font(.body.weight(.medium)).lineLimit(Theme.rowTitleLines)
                                    Text(dataset.code).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }.foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading).padding(Theme.rowPadding)
                                    .background(keyboardID == dataset.id ? accent.opacity(Theme.selectionOpacity) : .clear, in: RoundedRectangle(cornerRadius: Theme.rowCorner))
                                    .contentShape(Rectangle())
                            }.buttonStyle(PressStyle()).id(dataset.id)
                                .accessibilityAddTraits(keyboardID == dataset.id ? [.isSelected] : [])
                        }
                        if matches.count > visibleCount { Button("Afficher les jeux suivants") { visibleCount += 50 }.buttonStyle(.borderless).padding(Theme.rowPadding) }
                        if !loadingCatalogue && matches.isEmpty && error == nil { ContentUnavailableView("Aucun résultat", systemImage: "magnifyingglass") }
                    }
                }.onChange(of: keyboardID) { _, id in if let id { proxy.scrollTo(id) } }
            }
            if let error {
                Text(error).font(.callout).foregroundStyle(.secondary)
                Button("Réessayer") { Task { await loadCatalogue() } }.buttonStyle(.borderless)
            }
        }
    }

    private func seriesList(_ dataset: StatisticalDataset) -> some View {
        VStack(alignment: .leading, spacing: Theme.majorSpacing) {
            Text(dataset.title).font(.headline).textSelection(.enabled)
            if let starterError {
                Label(starterError, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.secondary)
            }
            CatalogueSearchField(query: $seriesQuery, prompt: "Rechercher une série…", isSearching: loadingStructure,
                submit: { if let key = keyboardSeriesKey ?? seriesMatches.first?.key { openSeries(key) } }, move: moveSeriesSelection)
            if !loadingStructure && seriesError == nil {
                Text("\(seriesMatches.count.formatted()) \(seriesMatches.count == 1 ? "série" : "séries")").font(.caption).foregroundStyle(.secondary)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Theme.rowSpacing) {
                        ForEach(Array(seriesMatches.prefix(visibleSeriesCount)), id: \.id) { item in
                            Button { openSeries(item.key) } label: {
                                VStack(alignment: .leading, spacing: Theme.rowTextSpacing) {
                                    Text(item.title).font(.body.weight(.medium)).lineLimit(Self.seriesTitleLines)
                                    let context = [item.frequency == .unknown ? nil : item.frequency.title, item.unitCode == nil ? nil : item.displayUnit].compactMap { $0 }.joined(separator: " · ")
                                    if !context.isEmpty { Text(context).font(.caption).foregroundStyle(.secondary) }
                                }
                                .foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading).padding(Theme.rowPadding)
                                .background(keyboardSeriesKey == item.key ? accent.opacity(Theme.selectionOpacity) : .clear, in: RoundedRectangle(cornerRadius: Theme.rowCorner))
                                .contentShape(Rectangle())
                            }.buttonStyle(PressStyle()).id(item.key)
                                .accessibilityAddTraits(keyboardSeriesKey == item.key ? [.isSelected] : [])
                        }
                        if seriesMatches.count > visibleSeriesCount { Button("Afficher les séries suivantes") { visibleSeriesCount += 50 }.buttonStyle(.borderless).padding(Theme.rowPadding) }
                        if !loadingStructure && seriesMatches.isEmpty && seriesError == nil { ContentUnavailableView("Aucune série trouvée", systemImage: "magnifyingglass") }
                    }
                }.onChange(of: keyboardSeriesKey) { _, key in if let key { proxy.scrollTo(key) } }
            }
            if let seriesError {
                Text(seriesError).font(.callout).foregroundStyle(.secondary)
                Button("Réessayer") { Task { await loadSeriesCatalogue() } }.buttonStyle(.borderless)
            }
            if let structure {
                DisclosureGroup("Recherche avancée", isExpanded: $showsAdvanced) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Self.formSpacing) {
                            ForEach(structure.dimensions) { dimension in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(dimension.title).foregroundStyle(.secondary).frame(maxWidth: Self.advancedLabelMaxWidth, alignment: .leading)
                                    Spacer(minLength: Theme.minorSpacing)
                                    if dimension.codes.count == 1, let code = dimension.codes.first { Text(code.title).multilineTextAlignment(.trailing) }
                                    else if dimension.codes.isEmpty {
                                        TextField(dimension.id, text: Binding(get: { values[dimension.id] ?? "" }, set: { values[dimension.id] = $0 }))
                                            .textFieldStyle(.roundedBorder).accessibilityLabel(dimension.title)
                                    } else {
                                        Button { choosingDimension = dimension } label: {
                                            HStack(spacing: Theme.minorSpacing) {
                                                Text(dimension.codes.first { $0.id == values[dimension.id] }?.title ?? "Choisir…").lineLimit(Self.valueLines).multilineTextAlignment(.trailing)
                                                Image(systemName: "chevron.up.chevron.down").font(.caption2)
                                            }
                                        }.buttonStyle(.borderless).accessibilityLabel("\(dimension.title) : \(values[dimension.id] ?? "à choisir")")
                                    }
                                }
                            }
                            TextField(source == .newYorkFed ? "Nom de la mesure" : source == .worldBank ? "Code du pays" : "Clé SDMX", text: $exactKey)
                                .textFieldStyle(.roundedBorder).font(.system(.callout, design: .monospaced)).accessibilityLabel("Clé exacte du repère")
                            Button("Afficher le repère") { openSeries(key) }.buttonStyle(.bordered).disabled(!canPreview)
                            if !dataset.detail.isEmpty { Text(dataset.detail).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }
                        }.padding(.top, Self.formSpacing)
                    }.frame(maxHeight: Self.advancedMaxHeight)
                }.font(.callout).disclosureGroupStyle(RowDisclosureStyle())
            }
        }
    }

    private var previewPane: some View {
        VStack(alignment: .leading, spacing: Theme.majorSpacing) {
            Button { selectedSeriesKey = nil; store.closePreview() } label: { Label("Séries", systemImage: "chevron.left") }.buttonStyle(.borderless)
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.majorSpacing) {
                    if store.isLoadingPreview { ProgressView("Chargement de l’historique…").controlSize(.small) }
                    if let value = store.previewSeries {
                        SeriesDetailView(series: value, preview: true)
                        HStack {
                            if let existing = store.followedMatch(for: value) {
                                Label("Déjà suivi via \(existing.originBadge)", systemImage: "checkmark").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                if existing.id != value.id { Button("Utiliser cette source") { _ = store.usePreviewSource() }.buttonStyle(.borderless) }
                                Button("Ouvrir") { store.show(existing); store.section = .overview; store.closePreview(); close?() }
                                    .buttonStyle(.borderedProminent).disabled(store.previewRequiresRefresh)
                            } else {
                                Button("Ajouter à mes repères") { _ = store.followStatisticalPreview() }.buttonStyle(.borderedProminent)
                                    .disabled(store.isLoadingPreview || store.previewError != nil)
                            }
                        }
                    }
                    if let error = store.previewError {
                        Label(error, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.secondary)
                        if store.previewRequiresRefresh {
                            Button("Actualiser mes repères") { Task { await store.refreshSeries() } }.buttonStyle(.borderless).disabled(store.isLoading)
                        } else if let key = selectedSeriesKey { Button("Réessayer") { openSeries(key) }.buttonStyle(.borderless) }
                    }
                }.padding(.bottom, Theme.majorSpacing)
            }
        }
    }

    private func starterRow(_ starter: StatisticalStarter) -> some View {
        Button { chooseStarter(starter) } label: {
            VStack(alignment: .leading, spacing: Theme.rowTextSpacing) {
                Text(starter.title).font(.body.weight(.medium)).lineLimit(Theme.rowTitleLines)
                Text(datasets.first(where: starter.matches)?.title ?? starter.datasetCode)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(Theme.rowTitleLines)
            }.foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading).padding(Theme.rowPadding)
                .contentShape(Rectangle())
        }.buttonStyle(PressStyle()).accessibilityLabel("\(starter.title), \(source.title)")
    }
    private func chooseStarter(_ starter: StatisticalStarter) {
        guard let dataset = datasets.first(where: starter.matches) else { return }
        starterError = nil
        if selectedID == dataset.id, structure != nil, !loadingStructure, seriesError == nil {
            if let descriptor = catalogueSeries.first(where: { $0.key == starter.key }) {
                selectedSeriesKey = descriptor.key; openSeries(descriptor.key)
            } else {
                starterError = "Cette suggestion n’apparaît plus dans le catalogue officiel. Recherchez une série dans le catalogue complet."
            }
            return
        }
        pendingStarter = starter
        if selectedID == dataset.id {
            if !loadingStructure { Task { await loadSeriesCatalogue() } }
        } else {
            selectedID = dataset.id
        }
    }
    private func openSeries(_ key: String) {
        guard let selected, let structure else { return }
        selectedSeriesKey = key
        store.openStatisticalPreview(dataset: selected, structure: structure, key: key)
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
    private func loadSeriesCatalogue() async {
        store.closePreview(); selectedSeriesKey = nil; structure = nil; values = [:]; exactKey = ""; catalogueSeries = []
        seriesQuery = ""; seriesError = nil; showsAdvanced = false; visibleSeriesCount = 50; keyboardSeriesKey = nil
        guard let selected else { return }
        let id = selected.id; loadingStructure = true
        defer { if selectedID == id { loadingStructure = false } }
        do {
            let client = StatisticalClient()
            let value = try await client.structure(dataset: selected)
            try Task.checkCancellation(); guard selectedID == id else { return }
            structure = value
            values = Dictionary(value.dimensions.compactMap { $0.codes.count == 1 ? ($0.id, $0.codes[0].id) : nil }, uniquingKeysWith: { _, new in new })
            let items = try await client.seriesCatalogue(dataset: selected, structure: value)
            try Task.checkCancellation(); guard selectedID == id else { return }
            catalogueSeries = items; keyboardSeriesKey = seriesMatches.first?.key
            if let starter = pendingStarter, starter.matches(selected) {
                pendingStarter = nil
                if let descriptor = items.first(where: { $0.key == starter.key }) {
                    selectedSeriesKey = descriptor.key; keyboardSeriesKey = descriptor.key
                    openSeries(descriptor.key)
                } else {
                    starterError = "Cette suggestion n’apparaît plus dans le catalogue officiel. Recherchez une série dans le catalogue complet."
                }
            }
        } catch is CancellationError { }
        catch { if selectedID == id { seriesError = error.localizedDescription } }
    }
    private func moveSelection(_ offset: Int) {
        let items = matches; guard !items.isEmpty else { return }
        let index = items.firstIndex { $0.id == keyboardID } ?? 0
        let next = min(max(index + offset, 0), items.count - 1)
        visibleCount = max(visibleCount, next + 1); keyboardID = items[next].id
    }
    private func moveSeriesSelection(_ offset: Int) {
        let items = seriesMatches; guard !items.isEmpty else { return }
        let index = items.firstIndex { $0.key == keyboardSeriesKey } ?? 0
        let next = min(max(index + offset, 0), items.count - 1)
        visibleSeriesCount = max(visibleSeriesCount, next + 1); keyboardSeriesKey = items[next].key
    }
}

private struct StatisticalCodePicker: View {
    private static let size = CGSize(width: 490, height: 470)
    @Environment(\.dismiss) private var dismiss
    let dimension: StatisticalDimension
    let selected: String?
    let choose: (String) -> Void
    @State private var query = ""
    @FocusState private var searchFocused: Bool
    private var codes: [StatisticalCode] { dimension.codes.filter { query.isEmpty || ($0.title + " " + $0.id).localizedStandardContains(query) } }
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.majorSpacing) {
            Text(dimension.title).font(.headline)
            TextField("Rechercher une valeur ou un code…", text: $query).textFieldStyle(.roundedBorder).focused($searchFocused)
                .onSubmit { if codes.count == 1, let code = codes.first { choose(code.id); dismiss() } }
            List(codes) { code in
                Button { choose(code.id); dismiss() } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: Theme.rowSpacing) { Text(code.title); Text(code.id).font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        if selected == code.id { Image(systemName: "checkmark") }
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain).padding(.vertical, Theme.rowSpacing)
            }.listStyle(.plain)
            HStack { Text("\(codes.count.formatted()) \(codes.count == 1 ? "valeur" : "valeurs")").font(.caption).foregroundStyle(.secondary); Spacer(); Button("Fermer") { dismiss() }.keyboardShortcut(.cancelAction) }
        }.padding(Theme.majorSpacing).frame(width: Self.size.width, height: Self.size.height).onAppear { searchFocused = true }
    }
}
