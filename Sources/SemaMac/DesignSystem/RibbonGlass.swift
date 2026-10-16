import AppKit
import SwiftUI

enum MenuRibbonPosition: String, CaseIterable, Identifiable {
    case top, bottom, left, right
    var id: String { rawValue }
    var isVertical: Bool { self == .left || self == .right }
    var title: String {
        switch self { case .top: "Haut"; case .bottom: "Bas"; case .left: "Gauche"; case .right: "Droite" }
    }
    var symbol: String {
        switch self {
        case .top: "rectangle.topthird.inset.filled"
        case .bottom: "rectangle.bottomthird.inset.filled"
        case .left: "rectangle.leadingthird.inset.filled"
        case .right: "rectangle.trailingthird.inset.filled"
        }
    }

    func frame(in screen: NSScreen) -> NSRect {
        var available = screen.visibleFrame.insetBy(dx: MenuRibbonLayout.screenInset, dy: MenuRibbonLayout.screenInset)
        available.size.height = max(0, min(available.maxY, screen.frame.maxY - screen.safeAreaInsets.top) - available.minY)
        let width = min(MenuRibbonLayout.verticalWidth, available.width)
        let height = min(MenuRibbonLayout.height, available.height)
        switch self {
        case .top: return NSRect(x: available.minX, y: available.maxY - height, width: available.width, height: height)
        case .bottom: return NSRect(x: available.minX, y: available.minY, width: available.width, height: height)
        case .left: return NSRect(x: available.minX, y: available.minY, width: width, height: available.height)
        case .right: return NSRect(x: available.maxX - width, y: available.minY, width: width, height: available.height)
        }
    }

    var revealOffset: CGVector {
        let offset = MenuRibbonLayout.revealOffset
        switch self {
        case .top: return CGVector(dx: 0, dy: offset)
        case .bottom: return CGVector(dx: 0, dy: -offset)
        case .left: return CGVector(dx: -offset, dy: 0)
        case .right: return CGVector(dx: offset, dy: 0)
        }
    }
}

/// A separate native backdrop per card leaves the space between cards transparent.
private struct RibbonGlassBackdrop: NSViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = MenuRibbonLayout.cardCornerRadius
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
    }
}

private enum RibbonGlassStyle {
    static let darkVeil = 0.10
    static let lightVeil = 0.20
    static let darkTint = 0.22
    static let lightTint = 0.12
}

/// A thin highlight describes the glass edge; labels stay outside its vibrancy.
struct RibbonSurface: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.semaGlassTint) private var glassTint
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    var emphasized = false

    func body(content: Content) -> some View {
        let opaque = reduceTransparency || contrast == .increased
        let shape = RoundedRectangle(cornerRadius: MenuRibbonLayout.cardCornerRadius, style: .continuous)
        content
            .background {
                if opaque {
                    shape.fill(SemaTheme.surface)
                    shape.fill(glassTint.opacity(0.06))
                }
                else {
                    RibbonGlassBackdrop()
                    shape.fill(colorScheme == .dark ? Color.black.opacity(RibbonGlassStyle.darkVeil)
                                                    : Color.white.opacity(RibbonGlassStyle.lightVeil))
                    shape.fill(LinearGradient(colors: [glassTint.opacity(colorScheme == .dark ? RibbonGlassStyle.darkTint : RibbonGlassStyle.lightTint), glassTint.opacity(0.04)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                    shape.fill(Color.white.opacity(emphasized ? 0.07 : 0.025))
                }
            }
            .overlay {
                shape.strokeBorder(LinearGradient(colors: [.white.opacity(colorScheme == .dark ? 0.16 : 0.65),
                                                           .white.opacity(0.025)], startPoint: .topLeading,
                                                  endPoint: .bottomTrailing), lineWidth: 0.5)
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
            .shadow(color: .black.opacity(emphasized ? 0.12 : 0.055), radius: emphasized ? 10 : 5, x: 0, y: 3)
    }
}
