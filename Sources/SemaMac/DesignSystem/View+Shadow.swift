// Pose sur une vue les couches d'ombre d'une élévation du patron.
import SemaDesign
import SwiftUI

private enum ShadowConversion {
    /// A SwiftUI shadow radius is about half a CSS blur.
    static let radiusPerBlur: CGFloat = 0.5
}

/// Deux appels fixes : la couche proche, puis la couche lointaine.
/// Une élévation à une seule couche pose une ombre lointaine transparente.
private struct ElevationModifier: ViewModifier {
    let near: ShadowLayer
    let far: ShadowLayer?

    func body(content: Content) -> some View {
        content
            .shadow(
                color: near.color,
                radius: near.blur * ShadowConversion.radiusPerBlur,
                x: near.x,
                y: near.y
            )
            .shadow(
                color: far?.color ?? .clear,
                radius: (far?.blur ?? 0) * ShadowConversion.radiusPerBlur,
                x: far?.x ?? 0,
                y: far?.y ?? 0
            )
    }
}

extension View {
    func elevation(_ layers: [ShadowLayer]) -> some View {
        modifier(ElevationModifier(near: layers[0], far: layers.dropFirst().first))
    }
}
