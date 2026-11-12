// Couleurs, rayons, rythme et ombres partagés par toutes les vues.
import AppKit
import SemaDesign
import SwiftUI

@MainActor
enum Theme {
    static let surface = Color(nsColor: NSColor(name: "SemaElevatedSurface") { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0.16, green: 0.16, blue: 0.16, alpha: 1)
            : .controlBackgroundColor
    })
    static let sidebarBackground = Color(nsColor: NSColor(name: "SemaSidebarBackground") { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0.12, green: 0.12, blue: 0.12, alpha: 1)
            : NSColor(white: 0.97, alpha: 1)
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
    // One radius per role (Espace et forme 1.1): selectable rows, cards inside a view, surfaces and floating panels.
    static let rowCorner = Radius.block
    static let cardCorner = Radius.card
    static let surfaceCorner = Radius.card
    // Selectable rows share their inset, gap, text rhythm and title length.
    static let rowPadding = Spacing.s12
    static let rowSpacing = Spacing.s4
    static let rowTextSpacing = Spacing.s8
    static let rowTitleLines = 3
    static let settingsRowPadding = Spacing.s6
    static let settingsTextSpacing = Spacing.s4
    static let iconButtonSize: CGFloat = 26
    // Inset of content from the edge of a surface or of the window.
    static let contentPadding = Spacing.s32
    // Vertical rhythm: the minor unit separates related items, the major unit separates groups.
    static let minorSpacing = Spacing.s8
    static let majorSpacing = Spacing.s24
    static let badgeVerticalInset = Spacing.s6
    static let badgeFillOpacity = 0.12
    // One-pixel rule; the shadow, not the stroke, tells the height.
    static let hairline: CGFloat = 1
    static let hoverDuration = DesignDuration.fast

    static let menuBarIcon: NSImage = {
        let renderer = ImageRenderer(content: Symbol(isMenuBarIcon: true).foregroundStyle(.black).frame(width: 18, height: 18))
        renderer.scale = 2
        let image = renderer.nsImage ?? NSImage(systemSymbolName: "waveform.path", accessibilityDescription: "sema")!
        image.isTemplate = true
        return image
    }()
}

/// Shared black shadows: opacity, blur and offset of each elevated surface.
extension Theme {
    struct Shadow {
        let opacity: Double
        let radius: CGFloat
        var x: CGFloat = 0
        let y: CGFloat

        // Espace et forme 1.1: level 1 rests (0 1 2), level 2 floats (0 8 24), level 3 is a window (0 24 64).
        // A SwiftUI radius is about half a CSS blur.
        static let contact = Shadow(opacity: 0.04, radius: 1, y: 1)
        static let contactDark = Shadow(opacity: 0.16, radius: 1, y: 1)
        static let plane = Shadow(opacity: 0.06, radius: 12, y: 8)
        static let planeDark = Shadow(opacity: 0.20, radius: 12, y: 8)
        static let cardResting = Shadow(opacity: 0.08, radius: 1, y: 1)
        static let card = Shadow(opacity: 0.12, radius: 12, y: 8)
        static let sidebar = Shadow(opacity: 0.12, radius: 12, y: 8)
        static let switcher = Shadow(opacity: 0.18, radius: 32, y: 24)
    }
}

extension View {
    func shadow(_ shadow: Theme.Shadow) -> some View {
        self.shadow(color: .black.opacity(shadow.opacity), radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
