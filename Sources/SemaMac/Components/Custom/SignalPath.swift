// Géométrie de la courbe du logo repère : une ligne qui monte et se pose sur un palier.
// Source unique du logo : `scripts/export_signe.py` lit ces constantes pour fabriquer les SVG de `Resources/Brand/` et de `site/dist/brand/`, et `controler.sh` refuse un export périmé.
// @documentation aucune
// @decision docs/decisions/2026-11-12-composant-signe-de-la-marque.md
import SwiftUI

struct SignalPath: Shape {
    /// Côté du carré où le signe est dessiné, en unités du signe.
    static let viewBox: CGFloat = 320
    /// Épaisseur du trait de la ligne, en unités du signe.
    static let stroke: CGFloat = 36
    /// La ligne part bas à gauche, monte le long d’une courbe, puis file à plat vers la droite.
    static let start = CGPoint(x: 24, y: 245)
    static let control1 = CGPoint(x: 114, y: 245)
    static let control2 = CGPoint(x: 136, y: 91)
    /// Centre du point sarcelle où la ligne se pose.
    static let dotCenter = CGPoint(x: 216, y: 91)
    static let end = CGPoint(x: 296, y: 91)
    /// Rayon visible du point, et rayon du vide qui le sépare de la ligne.
    static let dotRadius: CGFloat = 27
    static let gapRadius: CGFloat = 41
    /// L’icône de l’app : un carré de `appIconSize` à tuile arrondie ; le signe se place à `appIconOffset` dedans.
    static let appIconSize: CGFloat = 512
    static let appIconInset: CGFloat = 3
    static let appIconCorner: CGFloat = 115
    static let appIconEdge: CGFloat = 6
    static let appIconOffset = CGPoint(x: 96, y: 123)
    /// Le cadre du signe seul, en unités de l’icône : le signe avec une marge égale tout autour.
    static let artboard = CGRect(x: 80, y: 170, width: 352, height: 240)

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: Self.start)
        path.addCurve(to: Self.dotCenter, control1: Self.control1, control2: Self.control2)
        path.addLine(to: Self.end)
        return path.applying(Self.transform(in: rect))
    }

    /// Met les unités du signe à l’échelle du plus grand carré centré du rectangle.
    static func transform(in rect: CGRect) -> CGAffineTransform {
        let side = min(rect.width, rect.height)
        let scale = side / viewBox
        return CGAffineTransform(a: scale, b: 0, c: 0, d: scale,
                                 tx: rect.midX - side / 2, ty: rect.midY - side / 2)
    }

}
