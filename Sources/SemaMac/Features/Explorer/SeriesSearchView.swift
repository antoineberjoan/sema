// Propose la recherche rapide locale et Webstat avec sélection au clavier.
import SwiftUI
import MarketCore

struct SeriesSearchView: View {
    private static let sheetWidth: CGFloat = 880
    private static let sheetHeight: CGFloat = 560
    private static let sheetPadding: CGFloat = 18
    private static let sectionSpacing: CGFloat = 18
    private static let modePickerWidth: CGFloat = 300
    private static let catalogueHeight: CGFloat = 420
    private static let resultsHeight: CGFloat = 320
    private static let searchSpacing: CGFloat = 12
    private static let searchTopPadding: CGFloat = 6
    private static let iconSpacing: CGFloat = 12
    private static let iconWidth: CGFloat = 20
    private static let textSpacing: CGFloat = 5
    private static let emptyTopPadding: CGFloat = 35
    private static let searchFont = Font.system(size: 18)
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
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Rechercher un repère…", text: $query)
                    .textFieldStyle(.plain).font(Self.searchFont).focused($isSearchFocused)
                    .accessibilityLabel("Rechercher un repère")
                    .onSubmit(openSelected)
                    .onKeyPress(.downArrow) { moveSelection(by: 1); return .handled }
                    .onKeyPress(.upArrow) { moveSelection(by: -1); return .handled }
                Text("⌘K").font(.callout).foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.rowPadding).padding(.top, Self.searchTopPadding)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Theme.rowSpacing) {
                        ForEach(results) { item in
                            Button { open(item) } label: {
                                HStack(spacing: Self.iconSpacing) {
                                    Image(systemName: store.isFavorite(item.id) ? "star.fill" : "chart.xyaxis.line")
                                        .foregroundStyle(accent).frame(width: Self.iconWidth)
                                    VStack(alignment: .leading, spacing: Self.textSpacing) {
                                        Text(MarketFormat.name(item)).font(.body.weight(.medium))
                                        Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer(minLength: Theme.minorSpacing)
                                    VStack(alignment: .trailing, spacing: Self.textSpacing) {
                                        Text(MarketFormat.value(item)).font(.body).monospacedDigit()
                                        Text(context(for: item))
                                            .font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }
                                .padding(Theme.rowPadding).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedID == item.id ? accent.opacity(Theme.selectionOpacity) : .clear, in: RoundedRectangle(cornerRadius: Theme.rowCorner))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PressStyle()).id(item.id)
                        }
                        if results.isEmpty {
                            ContentUnavailableView("Aucun repère trouvé", systemImage: "magnifyingglass",
                                description: Text("Essayez « OAT », « BCE », « inflation » ou « immobilier »."))
                                .padding(.top, Self.emptyTopPadding)
                        }
                    }
                }
                .frame(height: Self.resultsHeight)
                .onChange(of: selectedID) { _, id in if let id { proxy.scrollTo(id) } }
            }
            HStack {
                Text("↑ ↓ choisir · ↩ ouvrir").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Button("Fermer") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Ouvrir", action: openSelected).keyboardShortcut(.defaultAction)
                    .disabled(selectedID == nil).buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, Theme.rowPadding)
        }
            }
        .padding(Self.sheetPadding).frame(width: Self.sheetWidth, height: Self.sheetHeight).background(Theme.surface)
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
