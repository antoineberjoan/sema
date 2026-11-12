// Liste des résultats de recherche d’un repère, avec sa sélection : la feuille ⌘K et le panneau global la partagent.
import SemaDesign
import SwiftUI
import MarketCore

struct SeriesResultsView: View {
    private static let iconSpacing = DesignSpace.fieldGap
    private static let iconWidth: CGFloat = 16
    private static let textSpacing = DesignSpace.titleGap
    private static let emptyTopPadding = DesignSpace.pageInsetNarrow
    @Environment(AppStore.self) private var store
    @Environment(\.palette) private var palette
    private var accentText: Color { DesignColor.accentText(palette) }
    let results: [MarketSeries]
    @Binding var selectedID: String?
    let height: CGFloat
    let open: (MarketSeries) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignSpace.listGapDense) {
                    ForEach(results) { item in
                        Button { open(item) } label: { row(item) }.buttonStyle(PressStyle()).id(item.id)
                    }
                    if results.isEmpty {
                        ContentUnavailableView("Aucun repère trouvé", systemImage: "magnifyingglass",
                            description: Text("Essayez « OAT », « BCE », « inflation » ou « immobilier »."))
                            .padding(.top, Self.emptyTopPadding)
                    }
                }
            }
            .frame(height: height)
            .onChange(of: selectedID) { _, id in if let id { proxy.scrollTo(id) } }
        }
    }

    /// The result `offset` places away from the selected one, kept inside the list.
    static func moved(_ id: String?, by offset: Int, in results: [MarketSeries]) -> String? {
        guard !results.isEmpty else { return nil }
        let current = results.firstIndex { $0.id == id } ?? 0
        return results[min(max(current + offset, 0), results.count - 1)].id
    }

    private func row(_ item: MarketSeries) -> some View {
        HStack(spacing: Self.iconSpacing) {
            Image(systemName: store.isFavorite(item.id) ? "star.fill" : "chart.xyaxis.line")
                .foregroundStyle(accentText).frame(width: Self.iconWidth)
            VStack(alignment: .leading, spacing: Self.textSpacing) {
                Text(MarketFormat.name(item)).typeRole(.heading)
                Text(item.subtitle).typeRole(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: DesignSpace.fieldGap)
            VStack(alignment: .trailing, spacing: Self.textSpacing) {
                Text(MarketFormat.value(item)).typeRole(.body).monospacedDigit()
                Text(item.frequency?.title ?? "Fréquence non renseignée").typeRole(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(DesignSpace.rowInset).foregroundStyle(DesignColor.text).frame(maxWidth: .infinity, alignment: .leading)
        .background(selectedID == item.id ? DesignColor.selection(palette) : .clear, in: RoundedRectangle(cornerRadius: DesignRadius.block))
        .contentShape(Rectangle())
    }
}
