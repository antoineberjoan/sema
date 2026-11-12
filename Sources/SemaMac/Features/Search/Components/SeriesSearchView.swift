// Propose la recherche rapide locale et Webstat avec sélection au clavier.
import SemaDesign
import SwiftUI
import MarketCore

struct SeriesSearchView: View {
    private static let sheetWidth: CGFloat = 880
    private static let sheetHeight: CGFloat = 560
    private static let sheetPadding = DesignSpace.cardInset
    private static let sectionSpacing = DesignSpace.itemGap
    private static let modePickerWidth: CGFloat = 300
    private static let catalogueHeight: CGFloat = 420
    private static let resultsHeight: CGFloat = 320
    private static let searchSpacing = DesignSpace.fieldGap
    private static let searchTopPadding = DesignSpace.controlInsetDense
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var query = ""
    @State private var selectedID: String?
    @State private var catalogue = false

    private var results: [MarketSeries] { store.searchResults(for: query) }

    var body: some View {
        VStack(spacing: Self.sectionSpacing) {
            Picker("Où rechercher", selection: $catalogue) {
                Text("Mes repères").tag(false)
                Text("Catalogues").tag(true)
            }.pickerStyle(.segmented).frame(width: Self.modePickerWidth)
            if catalogue {
                SourceExplorerView(compact: true, close: { dismiss() }).frame(height: Self.catalogueHeight)
                HStack { Spacer(); Button("Fermer") { dismiss() }.keyboardShortcut(.cancelAction) }
            } else {
            HStack(spacing: Self.searchSpacing) {
                Image(systemName: "magnifyingglass").foregroundStyle(DesignColor.textMuted)
                TextField("Rechercher un repère…", text: $query)
                    .textFieldStyle(.plain).typeRole(.subheading).focused($isSearchFocused)
                    .accessibilityLabel("Rechercher un repère")
                    .onSubmit(openSelected)
                    .onKeyPress(.downArrow) { moveSelection(by: 1); return .handled }
                    .onKeyPress(.upArrow) { moveSelection(by: -1); return .handled }
                Text("⌘K").typeRole(.small).foregroundStyle(DesignColor.textMuted)
            }
            .padding(.horizontal, DesignSpace.rowInset).padding(.top, Self.searchTopPadding)
            SeriesResultsView(results: results, selectedID: $selectedID, height: Self.resultsHeight, open: open)
            HStack {
                Text("↑ ↓ choisir · ↩ ouvrir").typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                Spacer()
                Button("Fermer") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Ouvrir", action: openSelected).keyboardShortcut(.defaultAction)
                    .disabled(selectedID == nil).buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, DesignSpace.rowInset)
        }
            }
        .padding(Self.sheetPadding).frame(width: Self.sheetWidth, height: Self.sheetHeight).background(DesignColor.surface)
        .onAppear {
            // The search panel hands over its text and asks for the catalogues tab.
            if let seed = store.catalogueSeed { query = seed; catalogue = true; store.catalogueSeed = nil }
            selectedID = results.first?.id; isSearchFocused = true
        }
        .onChange(of: query) { _, _ in selectedID = results.first?.id }
        .onChange(of: catalogue) { _, selected in
            if selected { store.catalogueSearch.query = query } else { query = store.catalogueSearch.query }
        }
        .onDisappear { store.closePreview() }
    }

    private func moveSelection(by offset: Int) {
        selectedID = SeriesResultsView.moved(selectedID, by: offset, in: results)
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
