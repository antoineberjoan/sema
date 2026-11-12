// Saisit une recherche de catalogue au clavier : focus à l’ouverture, effacement, flèches pour parcourir les résultats.
import SemaDesign
import SwiftUI

struct CatalogueSearchField: View {
    private static let spacing = DesignSpace.fieldGap
    @Binding var query: String
    let prompt: String
    var isSearching = false
    let submit: () -> Void
    let move: (Int) -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Self.spacing) {
            Image(systemName: "magnifyingglass").foregroundStyle(DesignColor.textMuted)
            TextField(prompt, text: $query).textFieldStyle(.plain).focused($isFocused)
                .accessibilityLabel(prompt).onSubmit(submit)
                .onKeyPress(.downArrow) { move(1); return .handled }
                .onKeyPress(.upArrow) { move(-1); return .handled }
            if isSearching { ProgressView().controlSize(.small) }
            if !query.isEmpty {
                Button { query = ""; isFocused = true } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(DesignColor.textMuted) }
                    .buttonStyle(.plain).accessibilityLabel("Effacer la recherche").help("Effacer la recherche")
            }
        }
        .typeRole(.subheading).padding(DesignSpace.menuInset)
        .background(DesignColor.surface, in: RoundedRectangle(cornerRadius: DesignRadius.block))
        .onAppear { isFocused = true }
    }
}
