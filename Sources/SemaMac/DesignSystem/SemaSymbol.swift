// Trace le signe Palier avec une épaisseur optique adaptée à sa taille.
import SwiftUI

/// Palier — Référence: Antoine’s original curve, with optical weights for small sizes.
struct SemaSymbol: View {
    // Strokes in curve units: 2 pt at 18 pt in the menu bar, then heavier optical weights for small sizes.
    private static let menuBarStroke = SemaSignalPath.viewBox / 9
    private static let smallSide: CGFloat = 28
    private static let mediumSide: CGFloat = 96
    private static let smallStroke: CGFloat = 2.89
    private static let mediumStroke: CGFloat = 2.04
    private static let largeStroke: CGFloat = 1.224
    var isMenuBarIcon = false

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let scale = side / SemaSignalPath.viewBox
            // The 18 pt menu-bar symbol uses a 2 pt stroke.
            let lineWidth = isMenuBarIcon ? Self.menuBarStroke : (side < Self.smallSide ? Self.smallStroke : side < Self.mediumSide ? Self.mediumStroke : Self.largeStroke)
            SemaSignalPath()
                .stroke(style: StrokeStyle(lineWidth: lineWidth * scale,
                                          lineCap: .round, lineJoin: .round))
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
