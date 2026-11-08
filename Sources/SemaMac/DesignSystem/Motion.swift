// Durées, courbes et amplitudes de Mouvement 1.1, partagées par toutes les animations de l’app.
import SwiftUI

enum Motion {
    /// Frequent or keyboard action: no animation.
    static let instant: TimeInterval = 0
    /// Press feedback of a button.
    static let press: TimeInterval = 0.12
    /// Hover, color change, tooltip.
    static let fast: TimeInterval = 0.15
    /// Menu, drop-down list.
    static let standard: TimeInterval = 0.2
    /// Window, drawer, panel.
    static let wide: TimeInterval = 0.3
    /// Explanation or screen seen once.
    static let explain: TimeInterval = 0.55
    /// An exit lasts about 60 % of its entrance.
    static let exitRatio = 0.6

    /// An entrance starts slightly smaller, never from zero.
    static let scaleFrom: CGFloat = 0.96
    static let pressScale: CGFloat = 0.97
    static let shift: CGFloat = 4
    static let stagger: TimeInterval = 0.05

    /// Default curve for entrances and exits.
    static func easeOut(_ duration: TimeInterval) -> Animation { .timingCurve(0.23, 1, 0.32, 1, duration: duration) }
    /// Movement or transformation on screen.
    static func easeInOut(_ duration: TimeInterval) -> Animation { .timingCurve(0.77, 0, 0.175, 1, duration: duration) }
    /// Drawer, in the manner of iOS.
    static func drawer(_ duration: TimeInterval) -> Animation { .timingCurve(0.32, 0.72, 0, 1, duration: duration) }
}
