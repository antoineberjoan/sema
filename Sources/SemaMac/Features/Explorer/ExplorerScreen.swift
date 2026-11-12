// Rubrique Explorer : héberge l’explorateur des sources à sa hauteur minimale.
import SemaDesign
import SwiftUI

struct ExplorerScreen: View {
    var body: some View { SourceExplorerView().frame(minHeight: DesignLayout.explorerMinimumHeight) }
}
