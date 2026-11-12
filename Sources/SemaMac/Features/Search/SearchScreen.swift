// Panneau de recherche rapide : un champ, les repères trouvés, puis le détail du repère choisi sans ouvrir le hub.
import SemaDesign
import SwiftUI
import MarketCore

struct SearchScreen: View {
    static let size = CGSize(width: DesignLayout.searchPanelWidth, height: DesignLayout.searchPanelHeight)
    private static let panelPadding = DesignSpace.cardInset
    private static let fieldSpacing = DesignSpace.fieldGap
    private static let escapeRadius = DesignRadius.control
    @Environment(AppStore.self) private var store
    @Environment(\.palette) private var palette
    private var accentText: Color { DesignColor.accentText(palette) }
    @FocusState private var isFieldFocused: Bool
    @State private var query = ""
    @State private var selectedID: String?
    let model: SearchPanelModel
    let openInHub: (MarketSeries) -> Void
    let openCatalogues: (String) -> Void
    private var results: [MarketSeries] { store.searchResults(for: query) }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.fieldSpacing) {
            if let series = model.detail { detail(series) } else { search }
        }
        .padding(Self.panelPadding)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .modifier(RibbonSurface())
        .onAppear { selectedID = results.first?.id; isFieldFocused = true }
        .onChange(of: query) { _, _ in selectedID = results.first?.id }
    }

    private var search: some View {
        VStack(alignment: .leading, spacing: Self.fieldSpacing) {
            HStack(spacing: Self.fieldSpacing) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Rechercher un repère…", text: $query)
                    .textFieldStyle(.plain).typeRole(.subheading).focused($isFieldFocused)
                    .accessibilityLabel("Rechercher un repère")
                    .onSubmit(showSelected)
                    .onKeyPress(.downArrow) { move(by: 1); return .handled }
                    .onKeyPress(.upArrow) { move(by: -1); return .handled }
                Text("esc").typeRole(.small).foregroundStyle(.secondary)
                    .padding(.horizontal, DesignSpace.markInsetInline).padding(.vertical, DesignSpace.markInset)
                    .overlay(RoundedRectangle(cornerRadius: Self.escapeRadius).stroke(DesignColor.rule))
            }
            .padding(.horizontal, DesignSpace.rowInset)
            SeriesResultsView(results: results, selectedID: $selectedID, height: DesignLayout.searchResultsHeight) { model.detail = $0 }
            Button { openCatalogues(query) } label: {
                Label(query.isEmpty ? "Chercher dans les catalogues" : "Chercher « \(query) » dans les catalogues",
                      systemImage: "books.vertical").typeRole(.small)
            }
            .buttonStyle(.borderless).foregroundStyle(accentText).padding(.horizontal, DesignSpace.rowInset)
            Spacer(minLength: 0)
            Text("↑ ↓ choisir · ↩ voir · esc fermer").typeRole(.caption).foregroundStyle(.secondary)
                .padding(.horizontal, DesignSpace.rowInset)
        }
    }

    private func detail(_ series: MarketSeries) -> some View {
        VStack(alignment: .leading, spacing: Self.fieldSpacing) {
            RibbonCard(series: store.displayedSeries(series), period: store.period(for: series)) { openInHub(series) }
                .frame(height: DesignLayout.menuRibbonCardHeight)
            Spacer(minLength: 0)
            HStack {
                Text("esc retour").typeRole(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Ouvrir dans sema") { openInHub(series) }.keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, DesignSpace.rowInset)
        }
    }

    private func move(by offset: Int) { selectedID = SeriesResultsView.moved(selectedID, by: offset, in: results) }

    private func showSelected() {
        if let item = results.first(where: { $0.id == selectedID }) { model.detail = item }
    }
}
