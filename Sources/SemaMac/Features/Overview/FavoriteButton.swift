// Épingle ou retire une série des favoris depuis sa carte ou son détail.
import SwiftUI

struct FavoriteButton: View {
    @Environment(AppStore.self) private var store
    @Environment(\.semaAccent) private var accent
    let seriesID: String
    let seriesName: String
    var body: some View {
        Button { store.toggleFavorite(seriesID) } label: {
            Image(systemName: store.isFavorite(seriesID) ? "star.fill" : "star")
                .font(.callout).foregroundStyle(store.isFavorite(seriesID) ? accent : Color.secondary)
                .frame(width: Theme.iconButtonSize, height: Theme.iconButtonSize).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(store.isFavorite(seriesID) ? "Retirer des favoris" : "Ajouter aux favoris")
        .accessibilityLabel(store.isFavorite(seriesID) ? "Retirer \(seriesName) des favoris" : "Ajouter \(seriesName) aux favoris")
    }
}
