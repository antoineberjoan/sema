// Géométrie de la courbe Palier, dessin original d’Antoine.
import SwiftUI

struct SemaSignalPath: Shape {
    /// Side of the square in which the original curve is drawn.
    static let viewBox: CGFloat = 64
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / Self.viewBox
        var path = Path()
        path.move(to: CGPoint(x: 43, y: 166.683))
        path.addCurve(to: CGPoint(x: 118.362, y: 76.0449), control1: CGPoint(x: 92.9018, y: 166.683), control2: CGPoint(x: 111.233, y: 118.818))
        path.addCurve(to: CGPoint(x: 90.865, y: 86.229), control1: CGPoint(x: 122.436, y: 49.5664), control2: CGPoint(x: 94.9387, y: 55.6768))
        path.addCurve(to: CGPoint(x: 159.098, y: 96.413), control1: CGPoint(x: 84.7546, y: 136.131), control2: CGPoint(x: 140.767, y: 111.689))
        path.addCurve(to: CGPoint(x: 209, y: 94.3762), control1: CGPoint(x: 180.485, y: 79.1001), control2: CGPoint(x: 196.779, y: 95.3946))
        return path.applying(CGAffineTransform(a: 0.34 * scale, b: 0, c: 0,
                                             d: 0.34 * scale, tx: -10.84 * scale, ty: -6.41998 * scale))
    }
}
