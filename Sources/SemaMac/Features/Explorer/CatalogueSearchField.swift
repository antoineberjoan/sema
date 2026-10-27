// Saisit une recherche de catalogue au clavier : focus à l’ouverture, effacement, flèches pour parcourir les résultats.
import SwiftUI

struct CatalogueSearchField: View {
    private static let spacing: CGFloat = 10
    @Binding var query: String
    let prompt: String
    var isSearching = false
    let submit: () -> Void
    let move: (Int) -> Void
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: Self.spacing) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(prompt, text: $query).textFieldStyle(.plain).focused($focused)
                .accessibilityLabel(prompt).onSubmit(submit)
                .onKeyPress(.downArrow) { move(1); return .handled }
                .onKeyPress(.upArrow) { move(-1); return .handled }
            if isSearching { ProgressView().controlSize(.small) }
            if !query.isEmpty {
                Button { query = ""; focused = true } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .buttonStyle(.plain).accessibilityLabel("Effacer la recherche").help("Effacer la recherche")
            }
        }
        .font(.title3).padding(Theme.rowPadding)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.rowCorner))
        .onAppear { focused = true }
    }
}
