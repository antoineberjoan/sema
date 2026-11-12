// Pose sur une vue les couches d'ombre d'une élévation du patron.
import SemaDesign
import SwiftUI

private enum ShadowConversion {
    /// A SwiftUI shadow radius is about half a CSS blur.
    static let radiusPerBlur: CGFloat = 0.5
}

extension View {
    /// Applies each layer of an elevation, the nearest first.
    func shadow(_ layers: [ShadowLayer]) -> some View {
        layers.reduce(AnyView(self)) { view, layer in
            AnyView(view.shadow(color: layer.color, radius: layer.blur * ShadowConversion.radiusPerBlur, x: layer.x, y: layer.y))
        }
    }
}
