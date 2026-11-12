// Point sarcelle du logo repère, ou l’écart qui le détache de la ligne, dans le carré de `SignalPath`.
// @documentation aucune
// @decision docs/decisions/2026-11-12-composant-signe-de-la-marque.md
import SwiftUI

struct SignalDot: Shape {
    var radius = SignalPath.dotRadius

    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(origin: SignalPath.dotCenter, size: .zero).insetBy(dx: -radius, dy: -radius))
            .applying(SignalPath.transform(in: rect))
    }
}
