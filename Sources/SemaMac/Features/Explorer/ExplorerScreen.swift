// Rubrique Explorer : héberge l’explorateur des sources à sa hauteur minimale.
import SwiftUI

struct ExplorerScreen: View {
    private static let minimumHeight: CGFloat = 510
    var body: some View { SourceExplorerView().frame(minHeight: Self.minimumHeight) }
}
