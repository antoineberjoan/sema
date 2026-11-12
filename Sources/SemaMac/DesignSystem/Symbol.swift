// Trace le logo repère : la ligne, l’écart qui la détache du point, puis le point sarcelle.
import SemaDesign
import SwiftUI

/// Antoine’s mark (8 November 2026). In the menu bar the point follows the template colour.
struct Symbol: View {
    var isMenuBarIcon = false

    var body: some View {
        GeometryReader { geometry in
            let rect = CGRect(origin: .zero, size: geometry.size)
            let scale = min(rect.width, rect.height) / SignalPath.viewBox
            ZStack {
                SignalPath()
                    .stroke(style: StrokeStyle(lineWidth: SignalPath.stroke * scale, lineCap: .round, lineJoin: .round))
                SignalDot(radius: SignalPath.gapRadius).blendMode(.destinationOut)
                if isMenuBarIcon {
                    SignalDot()
                } else {
                    SignalDot().fill(DesignColor.accentControl(.brand))
                }
            }
            .compositingGroup()
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
