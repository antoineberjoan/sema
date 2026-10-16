import SwiftUI
import MarketCore

struct SeriesSearchView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.semaAccent) private var accent
    @FocusState private var isSearchFocused: Bool
    @State private var query = ""
    @State private var selectedID: String?
    @State private var catalogue = false

    private var results: [MarketSeries] {
        let ordered = store.favorites + store.macroSeries.filter { !store.isFavorite($0.id) }
        return SeriesSearch.results(in: ordered, query: query)
    }

    var body: some View {
        VStack(spacing: 18) {
            Picker("Où rechercher", selection: $catalogue) {
                Text("Mes repères").tag(false)
                Text("Catalogue Webstat").tag(true)
            }.pickerStyle(.segmented).frame(width: 300)
            if catalogue {
                CatalogueBrowserView(compact: true, close: { dismiss() }).frame(height: 420)
                HStack { Spacer(); Button("Fermer") { dismiss() }.keyboardShortcut(.cancelAction) }
            } else {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Rechercher un repère…", text: $query)
                    .textFieldStyle(.plain).font(.system(size: 18)).focused($isSearchFocused)
                    .accessibilityLabel("Rechercher un repère")
                    .onSubmit(openSelected)
                    .onKeyPress(.downArrow) { moveSelection(by: 1); return .handled }
                    .onKeyPress(.upArrow) { moveSelection(by: -1); return .handled }
                Text("⌘K").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12).padding(.top, 6)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(results) { item in
                            Button { open(item) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: store.isFavorite(item.id) ? "star.fill" : "chart.xyaxis.line")
                                        .foregroundStyle(accent).frame(width: 20)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.name).font(.system(size: 13, weight: .medium))
                                        Text(item.subtitle).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer(minLength: 8)
                                    VStack(alignment: .trailing, spacing: 5) {
                                        Text(MarketFormat.value(item)).font(.system(size: 13)).monospacedDigit()
                                        Text(context(for: item))
                                            .font(.system(size: 11)).foregroundStyle(.secondary)
                                    }
                                }
                                .padding(12).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedID == item.id ? accent.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 12))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(SemaPressStyle()).id(item.id)
                        }
                        if results.isEmpty {
                            ContentUnavailableView("Aucun repère trouvé", systemImage: "magnifyingglass",
                                description: Text("Essayez « OAT », « BCE », « inflation » ou « immobilier »."))
                                .padding(.top, 35)
                        }
                    }
                }
                .frame(height: 320)
                .onChange(of: selectedID) { _, id in if let id { proxy.scrollTo(id) } }
            }
            HStack {
                Text("↑ ↓ choisir · ↩ ouvrir").font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button("Fermer") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Ouvrir", action: openSelected).keyboardShortcut(.defaultAction)
                    .disabled(selectedID == nil).buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 12)
        }
            }
        .padding(18).frame(width: 880, height: 560).background(SemaTheme.surface)
        .onAppear { selectedID = results.first?.id; isSearchFocused = true }
        .onChange(of: query) { _, _ in selectedID = results.first?.id }
        .onChange(of: catalogue) { _, selected in
            if selected { store.catalogueSearch.query = query } else { query = store.catalogueSearch.query }
        }
        .onDisappear { store.closePreview() }
    }

    private func moveSelection(by offset: Int) {
        guard !results.isEmpty else { selectedID = nil; return }
        let current = results.firstIndex { $0.id == selectedID } ?? 0
        selectedID = results[min(max(current + offset, 0), results.count - 1)].id
    }

    private func context(for item: MarketSeries) -> String {
        if item.isDemo { return "Démo" }
        return item.frequency?.title ?? "Fréquence non renseignée"
    }

    private func openSelected() {
        if let item = results.first(where: { $0.id == selectedID }) { open(item) }
    }

    private func open(_ item: MarketSeries) {
        store.show(item)
        store.section = .overview
        dismiss()
    }
}
