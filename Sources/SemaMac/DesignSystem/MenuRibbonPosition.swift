// Bords d’écran où le bandeau peut s’ouvrir, avec leurs libellés et symboles.
import AppKit

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
