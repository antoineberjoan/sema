// Double ombre qui pose une surface sur la fenêtre.
import SwiftUI

/// A small contact shadow anchors the surface; a softer shadow separates its plane.
struct Elevation: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content
            .shadow(colorScheme == .dark ? .contactDark : .contact)
            .shadow(colorScheme == .dark ? .planeDark : .plane)
    }
}
