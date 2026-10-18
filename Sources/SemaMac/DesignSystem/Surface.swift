// Conteneur élevé standard : marge, fond et ombre partagés.
import SwiftUI

struct Surface<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(SemaTheme.contentPadding)
            .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: SemaTheme.surfaceCorner))
            .modifier(SemaElevation())
    }
}
