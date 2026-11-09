// Point sarcelle du logo repère, ou l’écart qui le détache de la ligne, dans le carré de `SignalPath`.
import SwiftUI

struct SignalDot: Shape {
    var radius = SignalPath.dotRadius

    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(origin: SignalPath.dotCenter, size: .zero).insetBy(dx: -radius, dy: -radius))
            .applying(SignalPath.transform(in: rect))
    }
}
