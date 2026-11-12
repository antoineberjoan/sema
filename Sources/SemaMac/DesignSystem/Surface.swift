// Conteneur élevé standard : marge, fond et ombre partagés.
import SemaDesign
import SwiftUI

struct Surface<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(Theme.contentPadding)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.surfaceCorner))
            .shadow(DesignElevation.raised)
    }
}
