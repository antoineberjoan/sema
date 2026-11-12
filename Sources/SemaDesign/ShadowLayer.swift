// One layer of a shadow, and the modifier that applies an elevation.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

/// One layer of a shadow, in points.
public struct ShadowLayer: Sendable {
    public let color: Color
    public let x: CGFloat
    public let y: CGFloat
    public let blur: CGFloat
    public let spread: CGFloat
}

/// Two fixed shadow calls: the near layer, then the far one. An elevation with one layer sets a transparent far shadow.
private struct ElevationModifier: ViewModifier {
    let layers: [ShadowLayer]

    /// A SwiftUI shadow radius is about half a CSS blur.
    private static let radiusPerBlur: CGFloat = 0.5

    func body(content: Content) -> some View {
        let near = layers.first
        let far = layers.dropFirst().first
        content
            .shadow(color: near?.color ?? .clear, radius: (near?.blur ?? 0) * Self.radiusPerBlur, x: near?.x ?? 0, y: near?.y ?? 0)
            .shadow(color: far?.color ?? .clear, radius: (far?.blur ?? 0) * Self.radiusPerBlur, x: far?.x ?? 0, y: far?.y ?? 0)
    }
}

extension View {
    /// Applies the layers of an elevation role, such as `DesignElevation.raised`.
    public func elevation(_ layers: [ShadowLayer]) -> some View {
        modifier(ElevationModifier(layers: layers))
    }
}
