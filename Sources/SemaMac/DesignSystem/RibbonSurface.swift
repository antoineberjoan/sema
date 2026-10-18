// Compose les cartes en matière macOS et leur repli opaque pour les réglages d’accessibilité.
import AppKit
import SwiftUI

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
        view.layer?.cornerRadius = SemaTheme.surfaceCorner
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
    static let maximumGrainOpacity = 0.16
    static let veilRange = 4.0
    static let tintRange = 2.0
    static let tintEndOpacity = 0.08
    static let opaqueTintOpacity = 0.06
    static let highlightOpacity = 0.025
    static let emphasizedHighlightOpacity = 0.07
    static let edgeDarkOpacity = 0.16
    static let edgeLightOpacity = 0.65
    static let edgeEndOpacity = 0.025
    static let grainScale: CGFloat = 2
}

/// A fixed tile keeps the texture still and avoids a render loop per card.
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

/// A thin highlight describes the glass edge; labels stay outside its vibrancy.
struct RibbonSurface: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.semaGlassTint) private var glassTint
    @Environment(\.semaGlassSettings) private var glass
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    var emphasized = false

    func body(content: Content) -> some View {
        let opaque = reduceTransparency || contrast == .increased
        let shape = RoundedRectangle(cornerRadius: SemaTheme.surfaceCorner, style: .continuous)
        // NSVisualEffectView owns the blur. Only the contrast veil changes opacity.
        let veil = (colorScheme == .dark ? RibbonGlassStyle.darkVeil : RibbonGlassStyle.lightVeil)
            * (1 - glass.transparency) * RibbonGlassStyle.veilRange
        let tint = (colorScheme == .dark ? RibbonGlassStyle.darkTint : RibbonGlassStyle.lightTint) * glass.tint * RibbonGlassStyle.tintRange
        content
            .background {
                if opaque {
                    shape.fill(SemaTheme.surface)
                    shape.fill(glassTint.opacity(RibbonGlassStyle.opaqueTintOpacity))
                }
                else {
                    RibbonGlassBackdrop()
                    shape.fill(colorScheme == .dark ? Color.black.opacity(veil) : Color.white.opacity(veil))
                    shape.fill(LinearGradient(colors: [glassTint.opacity(tint), glassTint.opacity(RibbonGlassStyle.tintEndOpacity * glass.tint)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                    if glass.grain > 0, let texture = RibbonGrain.image {
                        Image(decorative: texture, scale: RibbonGlassStyle.grainScale)
                            .resizable(resizingMode: .tile).interpolation(.none)
                            .clipShape(shape)
                            .opacity(glass.grain * RibbonGlassStyle.maximumGrainOpacity)
                            .blendMode(.softLight)
                            .allowsHitTesting(false).accessibilityHidden(true)
                    }
                    shape.fill(Color.white.opacity(emphasized ? RibbonGlassStyle.emphasizedHighlightOpacity : RibbonGlassStyle.highlightOpacity))
                }
            }
            .overlay {
                shape.strokeBorder(LinearGradient(colors: [.white.opacity(colorScheme == .dark ? RibbonGlassStyle.edgeDarkOpacity : RibbonGlassStyle.edgeLightOpacity),
                                                           .white.opacity(RibbonGlassStyle.edgeEndOpacity)], startPoint: .topLeading,
                                                  endPoint: .bottomTrailing), lineWidth: SemaTheme.hairline)
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
            .shadow(emphasized ? .card : .cardResting)
    }
}
