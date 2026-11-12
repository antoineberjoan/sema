// Présente le catalogue de la source et vérifie ses clôtures avant ajout aux repères.
import SemaDesign
import SwiftUI
import MarketCore

struct MarketExplorerView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    let provider: MarketProvider
    var close: (() -> Void)?
    @State private var query = ""
    @State private var catalogue: MarketCatalogue?
    @State private var results: [MarketInstrument] = []
    @State private var isCatalogueLoading = false
    @State private var catalogueError: String?
    @State private var retry = UUID()
    @State private var selectedID: String?
    @State private var isWeekly = false
    @State private var preview: MarketSeries?
    @State private var isLoading = false
    @State private var error: String?
    @State private var task: Task<Void, Never>?
    @State private var generation = UUID()
    private var starterCount: Int {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? catalogue?.starters.count ?? 0 : 0
    }
    private var selected: MarketInstrument? { results.first { $0.id == selectedID } }
    private var catalogueID: String {
        provider.rawValue + (store.sourceGenerations[provider.rawValue]?.uuidString ?? "")
            + String(store.isSourceEnabled(provider.rawValue)) + retry.uuidString
    }

    var body: some View {
        if !store.connectedMarkets.contains(provider) {
            ContentUnavailableView {
                Label("Connecter \(provider.title)", systemImage: "key")
            } description: { Text("Retrouvez les instruments avec votre clé personnelle.") }
            actions: { Button("Ouvrir les sources") { store.settingsTab = .sources; openSettings() } }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task { await store.checkMarketKeys() }
        } else {
            HStack(alignment: .top, spacing: DesignSpace.groupGap) {
                VStack(alignment: .leading, spacing: DesignSpace.fieldGap) {
                    TextField("Filtrer le catalogue…", text: $query).textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Filtrer les instruments \(provider.title)")
                        .disabled(catalogue == nil)
                    if isCatalogueLoading {
                        ProgressView("Chargement du catalogue…").controlSize(.small)
                    } else if let catalogueError {
                        Text(catalogueError).typeRole(.small).foregroundStyle(DesignColor.textMuted)
                        Button("Réessayer") { retry = UUID() }
                    }
                    List(selection: $selectedID) {
                        if starterCount > 0 {
                            Section("Pour commencer") { rows(results.prefix(starterCount)) }
                            Section("Catalogue") { rows(results.dropFirst(starterCount)) }
                        } else {
                            rows(results[...])
                        }
                    }.listStyle(.plain)
                    if let catalogue {
                        Text("\(results.count) instrument\(results.count == 1 ? "" : "s")").typeRole(.micro).foregroundStyle(DesignColor.textMuted)
                        Text(catalogue.scope).typeRole(.micro).foregroundStyle(DesignColor.textMuted)
                    }
                    Text(provider.quota).typeRole(.micro).foregroundStyle(DesignColor.textMuted)
                }.frame(width: DesignLayout.marketExplorerListWidth)
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSpace.groupGap) {
                        if let selected {
                            Picker("Historique", selection: $isWeekly) {
                                Text("Quotidien").tag(false)
                                Text("Hebdomadaire").tag(true)
                            }.pickerStyle(.segmented)
                            if provider == .alphaVantage, !isWeekly {
                                Text("Gratuit : 100 dernières séances. Pour un historique long, choisissez Hebdomadaire.")
                                    .typeRole(.micro).foregroundStyle(DesignColor.textMuted)
                            }
                            if let preview {
                                SeriesDetailView(series: preview, preview: true)
                                if store.isFollowing(preview.id) {
                                    Button("Ouvrir") { store.show(preview); store.section = .overview; close?() }
                                } else {
                                    Button("Ajouter à mes repères") { add(preview) }.buttonStyle(.borderedProminent)
                                        .disabled(isLoading || error != nil)
                                }
                            } else if !isLoading { Text(selected.name).typeRole(.section) }
                        } else if catalogue != nil {
                            ContentUnavailableView(results.isEmpty ? "Aucun instrument" : "Choisir un instrument",
                                                   systemImage: "chart.xyaxis.line")
                        }
                        if isLoading { ProgressView().controlSize(.small) }
                        if let error { Text(error).typeRole(.small).foregroundStyle(DesignColor.textMuted).textSelection(.enabled) }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }.task(id: catalogueID) { await loadCatalogue() }
                .onChange(of: query) { _, _ in filter() }
                .onChange(of: selectedID) { _, _ in loadPreview() }
                .onChange(of: isWeekly) { _, _ in loadPreview() }
                .onChange(of: store.connectedMarkets) { _, values in
                    if !values.contains(provider) { cancel(); catalogue = nil; results = []; selectedID = nil }
                }
                .onDisappear { cancel() }
        }
    }

    private func loadCatalogue() async {
        cancel(); catalogue = nil; results = []; selectedID = nil; preview = nil; error = nil
        catalogueError = nil; isCatalogueLoading = true
        do {
            let value = try await store.marketCatalogue(provider)
            try Task.checkCancellation()
            catalogue = value; filter(); isCatalogueLoading = false
        } catch {
            guard !Task.isCancelled else { return }
            catalogueError = error.localizedDescription; isCatalogueLoading = false
        }
    }
    private func rows(_ items: ArraySlice<MarketInstrument>) -> some View {
        ForEach(items) { item in
            VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                Text(item.name)
                Text(item.summary).typeRole(.micro).foregroundStyle(DesignColor.textMuted)
            }.tag(item.id).padding(.vertical, DesignSpace.rowInset)
        }
    }
    private func filter() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = catalogue?.instruments ?? []
        if text.isEmpty {
            let starters = catalogue?.starters ?? []
            let ids = Set(starters.map(\.id))
            results = starters + all.filter { !ids.contains($0.id) }
        } else {
            results = all.filter {
                $0.name.localizedStandardContains(text) || $0.symbol.localizedStandardContains(text)
                    || $0.exchange.localizedStandardContains(text)
            }
        }
        if let selectedID, !results.contains(where: { $0.id == selectedID }) { self.selectedID = nil }
    }
    private func cancel() { task?.cancel(); generation = UUID(); isLoading = false }
    private func loadPreview() {
        cancel(); preview = nil; error = nil
        guard let instrument = selected?.usingWeekly(isWeekly) else { return }
        let id = generation; isLoading = true
        task = Task {
            do {
                let value = try await store.fetchMarket(instrument)
                guard !Task.isCancelled, id == generation else { return }
                preview = value; isLoading = false
            } catch {
                guard !Task.isCancelled, id == generation else { return }
                self.error = error.localizedDescription; isLoading = false
            }
        }
    }
    private func add(_ value: MarketSeries) {
        guard store.isSourceEnabled(provider.rawValue), store.connectedMarkets.contains(provider) else { return }
        do { _ = try store.saveFollowed(value) }
        catch { self.error = "Le repère n’a pas pu être enregistré. Vos données précédentes sont conservées." }
    }
}
