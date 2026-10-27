// Signe sema prêt à poser dans une vue, à la taille demandée.
import SwiftUI

struct Mark: View {
    private static let insetRatio: CGFloat = 0.08
    var size: CGFloat = 30
    var body: some View {
        Symbol()
            .foregroundStyle(.primary)
            .padding(size * Self.insetRatio)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
