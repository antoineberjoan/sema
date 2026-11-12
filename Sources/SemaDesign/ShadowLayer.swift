// One layer of a shadow, read by the shadow roles.
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
