// Géométrie de la courbe du logo repère d’Antoine : une ligne qui monte et se pose sur un palier.
import SwiftUI

struct SignalPath: Shape {
    /// Side of the square in which the mark is drawn, centred from the 512 pt app icon.
    static let viewBox: CGFloat = 320
    /// Stroke of the line, in mark units.
    static let stroke: CGFloat = 36
    /// Centre of the teal point where the line settles.
    static let dotCenter = CGPoint(x: 216, y: 91)
    /// Visible radius of the point, and radius of the gap that separates it from the line.
    static let dotRadius: CGFloat = 27
    static let gapRadius: CGFloat = 41

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 24, y: 245))
        path.addCurve(to: Self.dotCenter, control1: CGPoint(x: 114, y: 245), control2: CGPoint(x: 136, y: 91))
        path.addLine(to: CGPoint(x: 296, y: 91))
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
