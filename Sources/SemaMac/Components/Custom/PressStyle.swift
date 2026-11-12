// Retour d’appui des boutons, sans mouvement quand les animations sont réduites.
// @documentation https://developer.apple.com/documentation/swiftui/buttonstyle
// @decision docs/decisions/2026-11-12-composant-press-style.md
import SemaDesign
import SwiftUI

struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? DesignOpacity.pressPressedOpacity : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? DesignMotion.pressScale : 1)
            .animation(reduceMotion ? nil : Animation.timingCurve(DesignEase.out, duration: DesignDuration.press), value: configuration.isPressed)
    }
}
