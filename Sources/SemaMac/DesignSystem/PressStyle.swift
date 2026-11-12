// Retour d’appui des boutons, sans mouvement quand les animations sont réduites.
import SemaDesign
import SwiftUI

struct PressStyle: ButtonStyle {
    private static let pressedOpacity = 0.82
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? Self.pressedOpacity : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? DesignMotion.pressScale : 1)
            .animation(reduceMotion ? nil : Animation.timingCurve(DesignEase.out, duration: DesignDuration.press), value: configuration.isPressed)
    }
}
