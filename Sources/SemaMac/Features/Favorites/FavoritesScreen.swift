// Rubrique Favoris : la grille des repères épinglés.
import SemaDesign
import SwiftUI

struct FavoritesScreen: View {
    private static let emptyMinHeight: CGFloat = 380
    private static let tileMinWidth: CGFloat = 250
    @Environment(AppStore.self) private var store

    var body: some View {
        if store.favorites.isEmpty {
            ContentUnavailableView("Votre veille commence ici", systemImage: "star",
                                   description: Text("Ajoutez des indicateurs avec l’étoile pour les retrouver ici."))
                .frame(maxWidth: .infinity, minHeight: Self.emptyMinHeight)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: Self.tileMinWidth), spacing: DesignSpace.itemGap)], spacing: DesignSpace.itemGap) {
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
