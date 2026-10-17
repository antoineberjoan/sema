// Couleurs, rayons, rythme et ombres partagés par toutes les vues.
import AppKit
import SwiftUI

@MainActor
enum SemaTheme {
    static let surface = Color(nsColor: NSColor(name: "SemaElevatedSurface") { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0.16, green: 0.16, blue: 0.16, alpha: 1)
            : .controlBackgroundColor
    })
    static let sidebarSecondaryText = Color(nsColor: NSColor(name: "SemaSidebarSecondaryText") { appearance in
        let dark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return NSColor(white: dark ? 0.76 : 0.36, alpha: 1)
    })
    // A selected item takes the same tint, neutral in the sidebar and accent elsewhere.
    static let selectionOpacity = 0.12
    static let sidebarSelection = Color.primary.opacity(selectionOpacity)
    static let hoverFill = Color.primary.opacity(0.04)
    // A resting control, such as a search field or an unselected chip, sits on a quieter fill than a hover.
    static let quietFill = Color.primary.opacity(0.035)
    static let background = Color(nsColor: .windowBackgroundColor)
    static let separator = Color(nsColor: .separatorColor).opacity(0.5)
    // One radius per role: selectable rows, cards inside a view, surfaces and floating panels.
    static let rowCorner: CGFloat = 12
    static let cardCorner: CGFloat = 16
    static let surfaceCorner: CGFloat = 22
    // Selectable rows share their inset, gap, text rhythm and title length.
    static let rowPadding: CGFloat = 12
    static let rowSpacing: CGFloat = 4
    static let rowTextSpacing: CGFloat = 7
    static let rowTitleLines = 3
    static let settingsRowPadding: CGFloat = 5
    static let settingsTextSpacing: CGFloat = 4
    static let iconButtonSize: CGFloat = 26
    // Inset of content from the edge of a surface or of the window.
    static let contentPadding: CGFloat = 26
    // Vertical rhythm: the minor unit separates related items, the major unit separates groups.
    static let minorSpacing: CGFloat = 8
    static let majorSpacing: CGFloat = 24
    static let hairline: CGFloat = 0.5
    static let hoverDuration = 0.14

    static let menuBarIcon: NSImage = {
        let renderer = ImageRenderer(content: SemaSymbol(isMenuBarIcon: true).foregroundStyle(.black).frame(width: 18, height: 18))
        renderer.scale = 2
        let image = renderer.nsImage ?? NSImage(systemSymbolName: "waveform.path", accessibilityDescription: "sema")!
        image.isTemplate = true
        return image
    }()
}

/// Shared black shadows: opacity, blur and offset of each elevated surface.
extension SemaTheme {
    struct Shadow {
        let opacity: Double
        let radius: CGFloat
        var x: CGFloat = 0
        let y: CGFloat

        static let contact = Shadow(opacity: 0.04, radius: 2, y: 1)
        static let contactDark = Shadow(opacity: 0.16, radius: 2, y: 1)
        static let plane = Shadow(opacity: 0.06, radius: 16, y: 6)
        static let planeDark = Shadow(opacity: 0.20, radius: 16, y: 6)
        static let cardResting = Shadow(opacity: 0.055, radius: 5, y: 3)
        static let card = Shadow(opacity: 0.12, radius: 10, y: 3)
        static let sidebar = Shadow(opacity: 0.12, radius: 14, x: 4, y: 6)
        static let switcher = Shadow(opacity: 0.18, radius: 28, y: 12)
    }
}

extension View {
    func shadow(_ shadow: SemaTheme.Shadow) -> some View {
        self.shadow(color: .black.opacity(shadow.opacity), radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
