// Épingle ou retire une série des favoris depuis sa carte ou son détail.
import SemaDesign
import SwiftUI

struct FavoriteButton: View {
    @Environment(AppStore.self) private var store
    @Environment(\.palette) private var palette
    private var accentText: Color { DesignColor.accentText(palette) }
    let seriesID: String
    let seriesName: String
    var body: some View {
        Button { store.toggleFavorite(seriesID) } label: {
            Image(systemName: store.isFavorite(seriesID) ? "star.fill" : "star")
                .typeRole(.small).foregroundStyle(store.isFavorite(seriesID) ? accentText : DesignColor.textMuted)
                .frame(width: DesignIcon.buttonSize, height: DesignIcon.buttonSize).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(store.isFavorite(seriesID) ? "Retirer des favoris" : "Ajouter aux favoris")
        .accessibilityLabel(store.isFavorite(seriesID) ? "Retirer \(seriesName) des favoris" : "Ajouter \(seriesName) aux favoris")
    }
}
