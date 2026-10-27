// Retour d’appui des boutons, sans mouvement quand les animations sont réduites.
import SwiftUI

struct PressStyle: ButtonStyle {
    private static let pressedOpacity = 0.82
    private static let pressedScale: CGFloat = 0.99
    private static let response = 0.22
    private static let damping = 0.85
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? Self.pressedOpacity : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? Self.pressedScale : 1)
            .animation(reduceMotion ? nil : .spring(response: Self.response, dampingFraction: Self.damping), value: configuration.isPressed)
    }
}
