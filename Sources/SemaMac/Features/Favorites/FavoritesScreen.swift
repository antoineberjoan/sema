// Rubrique Favoris : la grille des repères épinglés.
import SemaDesign
import SwiftUI

struct FavoritesScreen: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        if store.favorites.isEmpty {
            ContentUnavailableView("Votre veille commence ici", systemImage: "star",
                                   description: Text("Ajoutez des indicateurs avec l’étoile pour les retrouver ici."))
                .frame(maxWidth: .infinity, minHeight: DesignLayout.favoritesEmptyMinHeight)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: DesignLayout.favoritesTileMinWidth), spacing: DesignSpace.itemGap)], spacing: DesignSpace.itemGap) {
                ForEach(store.favorites) { series in
                    IndicatorTile(series: series) {
                        store.show(series)
                        store.section = .overview
                    }
                }
            }
        }
    }
}
