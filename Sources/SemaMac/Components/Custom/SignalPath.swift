// Géométrie de la courbe du logo repère d’Antoine : une ligne qui monte et se pose sur un palier.
// @documentation aucune
// @decision docs/decisions/2026-11-12-composant-signe-de-la-marque.md
import SwiftUI

struct SignalPath: Shape {
    /// Side of the square in which the mark is drawn, in mark units.
    static let viewBox: CGFloat = 320
    /// Stroke of the line, in mark units.
    static let stroke: CGFloat = 36
    /// The line starts low on the left, climbs along one curve, then runs flat to the right.
    static let start = CGPoint(x: 24, y: 245)
    static let control1 = CGPoint(x: 114, y: 245)
    static let control2 = CGPoint(x: 136, y: 91)
    /// Centre of the teal point where the line settles.
    static let dotCenter = CGPoint(x: 216, y: 91)
    static let end = CGPoint(x: 296, y: 91)
    /// Visible radius of the point, and radius of the gap that separates it from the line.
    static let dotRadius: CGFloat = 27
    static let gapRadius: CGFloat = 41
    /// The app icon: a square of `appIconSize` with a rounded tile; the mark sits at `appIconOffset` inside it.
    static let appIconSize: CGFloat = 512
    static let appIconInset: CGFloat = 3
    static let appIconCorner: CGFloat = 115
    static let appIconEdge: CGFloat = 6
    static let appIconOffset = CGPoint(x: 96, y: 123)
    /// The frame of the mark alone, in app icon units: the mark with an equal margin around it.
    static let artboard = CGRect(x: 80, y: 170, width: 352, height: 240)

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: Self.start)
        path.addCurve(to: Self.dotCenter, control1: Self.control1, control2: Self.control2)
        path.addLine(to: Self.end)
        return path.applying(Self.transform(in: rect))
    }

    /// Scales mark units into the largest centred square of the rectangle.
    static func transform(in rect: CGRect) -> CGAffineTransform {
        let side = min(rect.width, rect.height)
        let scale = side / viewBox
        return CGAffineTransform(a: scale, b: 0, c: 0, d: scale,
                                 tx: rect.midX - side / 2, ty: rect.midY - side / 2)
    }

}
