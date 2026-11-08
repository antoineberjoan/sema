// Retour d’appui des boutons, sans mouvement quand les animations sont réduites.
import SwiftUI

struct PressStyle: ButtonStyle {
    private static let pressedOpacity = 0.82
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? Self.pressedOpacity : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? Motion.pressScale : 1)
            .animation(reduceMotion ? nil : Motion.easeOut(Motion.press), value: configuration.isPressed)
    }
}
