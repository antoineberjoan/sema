// Présente le catalogue de la source et vérifie ses clôtures avant ajout aux repères.
import SwiftUI
import MarketCore

struct MarketExplorerView: View {
    private static let listWidth: CGFloat = 310
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    let provider: MarketProvider
    var close: (() -> Void)?
    @State private var query = ""
    @State private var catalogue: MarketCatalogue?
    @State private var results: [MarketInstrument] = []
    @State private var catalogueLoading = false
    @State private var catalogueError: String?
    @State private var retry = UUID()
    @State private var selectedID: String?
    @State private var weekly = false
    @State private var preview: MarketSeries?
    @State private var loading = false
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
            HStack(alignment: .top, spacing: Theme.majorSpacing) {
                VStack(alignment: .leading, spacing: Theme.minorSpacing) {
                    TextField("Filtrer le catalogue…", text: $query).textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Filtrer les instruments \(provider.title)")
                        .disabled(catalogue == nil)
                    if catalogueLoading {
                        ProgressView("Chargement du catalogue…").controlSize(.small)
                    } else if let catalogueError {
                        Text(catalogueError).font(.callout).foregroundStyle(.secondary)
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
                        Text("\(results.count) instrument\(results.count == 1 ? "" : "s")").font(.caption).foregroundStyle(.secondary)
                        Text(catalogue.scope).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(provider.quota).font(.caption).foregroundStyle(.secondary)
                }.frame(width: Self.listWidth)
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.majorSpacing) {
                        if let selected {
                            Picker("Historique", selection: $weekly) {
                                Text("Quotidien").tag(false)
                                Text("Hebdomadaire").tag(true)
                            }.pickerStyle(.segmented)
                            if provider == .alphaVantage, !weekly {
                                Text("Gratuit : 100 dernières séances. Pour un historique long, choisissez Hebdomadaire.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if let preview {
                                SeriesDetailView(series: preview, preview: true)
                                if store.isFollowing(preview.id) {
                                    Button("Ouvrir") { store.show(preview); store.section = .overview; close?() }
                                } else {
                                    Button("Ajouter à mes repères") { add(preview) }.buttonStyle(.borderedProminent)
                                        .disabled(loading || error != nil)
                                }
                            } else if !loading { Text(selected.name).font(.title2) }
                        } else if catalogue != nil {
                            ContentUnavailableView(results.isEmpty ? "Aucun instrument" : "Choisir un instrument",
                                                   systemImage: "chart.xyaxis.line")
                        }
                        if loading { ProgressView().controlSize(.small) }
                        if let error { Text(error).font(.callout).foregroundStyle(.secondary).textSelection(.enabled) }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }.task(id: catalogueID) { await loadCatalogue() }
                .onChange(of: query) { _, _ in filter() }
                .onChange(of: selectedID) { _, _ in loadPreview() }
                .onChange(of: weekly) { _, _ in loadPreview() }
                .onChange(of: store.connectedMarkets) { _, values in
                    if !values.contains(provider) { cancel(); catalogue = nil; results = []; selectedID = nil }
                }
                .onDisappear { cancel() }
        }
    }

    private func loadCatalogue() async {
        cancel(); catalogue = nil; results = []; selectedID = nil; preview = nil; error = nil
        catalogueError = nil; catalogueLoading = true
        do {
            let value = try await store.marketCatalogue(provider)
            try Task.checkCancellation()
            catalogue = value; filter(); catalogueLoading = false
        } catch {
            guard !Task.isCancelled else { return }
            catalogueError = error.localizedDescription; catalogueLoading = false
        }
    }
    private func rows(_ items: ArraySlice<MarketInstrument>) -> some View {
        ForEach(items) { item in
            VStack(alignment: .leading, spacing: Theme.rowTextSpacing) {
                Text(item.name)
                Text(item.summary).font(.caption).foregroundStyle(.secondary)
            }.tag(item.id).padding(.vertical, Theme.rowPadding)
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
    private func cancel() { task?.cancel(); generation = UUID(); loading = false }
    private func loadPreview() {
        cancel(); preview = nil; error = nil
        guard let instrument = selected?.usingWeekly(weekly) else { return }
        let id = generation; loading = true
        task = Task {
            do {
                let value = try await store.fetchMarket(instrument)
                guard !Task.isCancelled, id == generation else { return }
                preview = value; loading = false
            } catch {
                guard !Task.isCancelled, id == generation else { return }
                self.error = error.localizedDescription; loading = false
            }
        }
    }
    private func add(_ value: MarketSeries) {
        guard store.isSourceEnabled(provider.rawValue), store.connectedMarkets.contains(provider) else { return }
        do { _ = try store.saveFollowed(value) }
        catch { self.error = "Le repère n’a pas pu être enregistré. Vos données précédentes sont conservées." }
    }
}
