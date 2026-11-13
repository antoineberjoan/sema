// Compose les cartes en matière macOS et leur repli isOpaque pour les réglages d’accessibilité.
// @documentation aucune
// @decision docs/decisions/2026-11-12-composant-ribbon-surface.md
import AppKit
import SemaDesign
import SwiftUI

/// Un fond natif séparé par carte laisse transparent l’espace entre les cartes.
private struct RibbonGlassBackdrop: NSViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = DesignRadius.card
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
    }
}

/// Une tuile fixe garde la texture immobile et évite une boucle de rendu par carte.
@MainActor
private enum RibbonGrain {
    static let image: CGImage? = {
        let size = 128
        var seed: UInt32 = 0x53454D41
        let pixels = (0..<(size * size)).map { _ -> UInt8 in
            seed = 1_664_525 &* seed &+ 1_013_904_223
            return UInt8(truncatingIfNeeded: seed >> 24)
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 8,
                       bytesPerRow: size, space: CGColorSpaceCreateDeviceGray(),
                       bitmapInfo: CGBitmapInfo(rawValue: 0), provider: provider,
                       decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }()
}

/// Un fin reflet décrit le bord du verre ; les libellés restent hors de sa vibrance.
struct RibbonSurface: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.palette) private var palette
    private var glassTint: Color { DesignColor.glassTint(palette) }
    @Environment(\.glassSettings) private var glass
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    var isEmphasized = false

    func body(content: Content) -> some View {
        let isOpaque = reduceTransparency || contrast == .increased
        let shape = RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
        // NSVisualEffectView gère le flou. Seul le voile de contraste change d’opacité.
        let veil = (colorScheme == .dark ? DesignOpacity.glassVeilDark : DesignOpacity.glassVeilLight)
            * (1 - glass.transparency) * DesignMeasure.glassVeilRange
        let tint = (colorScheme == .dark ? DesignOpacity.glassTintDark : DesignOpacity.glassTintLight) * glass.tint * DesignMeasure.glassTintRange
        content
            .background {
                if isOpaque {
                    shape.fill(DesignColor.surfaceRaised)
                    shape.fill(glassTint.opacity(DesignOpacity.glassTintOpaque))
                }
                else {
                    RibbonGlassBackdrop()
                    shape.fill(DesignColor.glassVeil.opacity(veil))
                    shape.fill(LinearGradient(colors: [glassTint.opacity(tint), glassTint.opacity(DesignOpacity.glassTintEnd * glass.tint)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                    if glass.grain > 0, let texture = RibbonGrain.image {
                        Image(decorative: texture, scale: CGFloat(DesignMeasure.glassGrainScale))
                            .resizable(resizingMode: .tile).interpolation(.none)
                            .clipShape(shape)
                            .opacity(glass.grain * DesignOpacity.glassGrainMax)
                            .blendMode(.softLight)
                            .allowsHitTesting(false).accessibilityHidden(true)
                    }
                    shape.fill(DesignColor.glassHighlight.opacity(isEmphasized ? DesignOpacity.glassHighlightEmphasized : DesignOpacity.glassHighlightRest))
                }
            }
            .overlay {
                shape.strokeBorder(LinearGradient(colors: [DesignColor.glassEdge.opacity(colorScheme == .dark ? DesignOpacity.glassEdgeDark : DesignOpacity.glassEdgeLight),
                                                           DesignColor.glassEdge.opacity(DesignOpacity.glassEdgeEnd)], startPoint: .topLeading,
                                                  endPoint: .bottomTrailing), lineWidth: DesignBorder.width)
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
            .elevation(isEmphasized ? DesignElevation.floating : DesignElevation.raised)
    }
}
