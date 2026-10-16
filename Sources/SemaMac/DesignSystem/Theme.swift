import AppKit
import SwiftUI
import MarketCore

enum SemaPalette: String, CaseIterable, Identifiable, Sendable {
    case graphite, teal, mint, lavender, sky, polar
    var id: String { rawValue }
    var title: String {
        switch self {
        case .teal: "Sarcelle"
        case .mint: "Menthe"
        case .lavender: "Lavande"
        case .sky: "Bleu ciel"
        case .polar: "Bleu polaire"
        case .graphite: "Graphite"
        }
    }
    var swatches: [UInt32] {
        switch self {
        case .teal: [0x265073, 0x2D9596, 0x9AD0C2, 0xECF4D6]
        case .mint: [0x8EC3B0, 0x9ED5C5, 0xBCEAD5, 0xDEF5E5]
        case .lavender: [0xD0A2F7, 0xDCBFFF, 0xE5D4FF, 0xF1EAFF]
        case .sky: [0x00A9FF, 0x89CFF3, 0xA0E9FF, 0xCDF5FD]
        case .polar: [0x053F56, 0x21A5EC, 0x90D2F5, 0xF2F3F7]
        case .graphite: [0x333333, 0x707070, 0xD6D6D6, 0xFAFAFA]
        }
    }
    private var lightAccent: UInt32 {
        switch self {
        case .teal: 0x1F6F73
        case .mint: 0x32755E
        case .lavender: 0x78499E
        case .sky: 0x007AB8
        case .polar: 0x097BAF
        case .graphite: 0x474747
        }
    }
    private var darkAccent: UInt32 {
        switch self {
        case .teal: 0x9AD0C2
        case .mint: 0x9ED5C5
        case .lavender: 0xD0A2F7
        case .sky: 0x89CFF3
        case .polar: 0x90D2F5
        case .graphite: 0xD6D6D6
        }
    }
    var accent: Color {
        Color(nsColor: NSColor(name: "SemaAccent-" + rawValue) { appearance in
            Self.nsColor(appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? darkAccent : lightAccent)
        })
    }
    // Native selected controls use white labels, so pastel swatches need a deeper tint.
    var controlAccent: Color { Color(nsColor: Self.nsColor(lightAccent)) }
    // The signature is the one coloured editorial surface in the Graphite ribbon.
    var signatureAccent: Color { self == .graphite ? Self.swatch(0x355A80) : controlAccent }
    var glassTint: Color {
        switch self {
        case .graphite: .clear
        case .teal: Self.swatch(0x2D9596)
        case .mint: Self.swatch(0x8EC3B0)
        case .lavender: Self.swatch(0xD0A2F7)
        case .sky: Self.swatch(0x00A9FF)
        case .polar: Self.swatch(0x21A5EC)
        }
    }
    static func swatch(_ hex: UInt32) -> Color { Color(nsColor: nsColor(hex)) }
    private static func nsColor(_ hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}

private struct SemaAccentKey: EnvironmentKey {
    static let defaultValue: Color = SemaPalette.graphite.accent
}

private struct SemaGlassTintKey: EnvironmentKey {
    static let defaultValue: Color = .clear
}

extension EnvironmentValues {
    var semaGlassTint: Color {
        get { self[SemaGlassTintKey.self] }
        set { self[SemaGlassTintKey.self] = newValue }
    }
    var semaAccent: Color {
        get { self[SemaAccentKey.self] }
        set { self[SemaAccentKey.self] = newValue }
    }
}

@MainActor
enum SemaTheme {
    static let surface = Color(nsColor: NSColor(name: "SemaElevatedSurface") { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0.16, green: 0.16, blue: 0.16, alpha: 1)
            : .controlBackgroundColor
    })
    static let background = Color(nsColor: .windowBackgroundColor)
    static let separator = Color(nsColor: .separatorColor).opacity(0.5)
    static let corner: CGFloat = 22

    static let menuBarIcon: NSImage = {
        let renderer = ImageRenderer(content: SemaSymbol(isMenuBarIcon: true).foregroundStyle(.black).frame(width: 18, height: 18))
        renderer.scale = 2
        let image = renderer.nsImage ?? NSImage(systemSymbolName: "waveform.path", accessibilityDescription: "sema")!
        image.isTemplate = true
        return image
    }()
}

enum MarketFormat {
    static func number(_ value: Decimal, digits: Int = 2, signed: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        let formatted = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "—"
        return signed && value > 0 ? "+" + formatted : formatted
    }

    static func value(_ series: MarketSeries) -> String {
        guard let value = series.latest?.value else { return "—" }
        let n = number(value, digits: series.fractionDigits)
        return n + (series.displayUnit.isEmpty ? "" : " " + series.displayUnit)
    }

    static func change(_ series: MarketSeries, period: HistoryPeriod) -> String {
        guard let delta = series.change(for: period) else { return series.descriptor?.variation == .unavailable ? "Variation non calculée" : "Historique insuffisant" }
        return number(delta, digits: 2, signed: true) + (series.unit == .percent ? " pt" : " %")
    }

    static func date(_ date: Date?) -> String {
        guard let date else { return "Date inconnue" }
        return date.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "fr_FR")))
    }

    static func double(_ value: Decimal) -> Double { NSDecimalNumber(decimal: value).doubleValue }
}

struct SemaMark: View {
    var size: CGFloat = 30
    var body: some View {
        SemaSymbol()
            .foregroundStyle(.primary)
            .padding(size * 0.08)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Palier — Référence: Antoine’s original curve, with optical weights for small sizes.
struct SemaSymbol: View {
    var isMenuBarIcon = false

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let scale = side / 64
            // The 18 pt menu-bar symbol uses a 2 pt stroke.
            let lineWidth = isMenuBarIcon ? 64.0 / 9 : (side < 28 ? 2.89 : side < 96 ? 2.04 : 1.224)
            SemaSignalPath()
                .stroke(style: StrokeStyle(lineWidth: lineWidth * scale,
                                          lineCap: .round, lineJoin: .round))
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

struct SemaSignalPath: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 64
        var path = Path()
        path.move(to: CGPoint(x: 43, y: 166.683))
        path.addCurve(to: CGPoint(x: 118.362, y: 76.0449), control1: CGPoint(x: 92.9018, y: 166.683), control2: CGPoint(x: 111.233, y: 118.818))
        path.addCurve(to: CGPoint(x: 90.865, y: 86.229), control1: CGPoint(x: 122.436, y: 49.5664), control2: CGPoint(x: 94.9387, y: 55.6768))
        path.addCurve(to: CGPoint(x: 159.098, y: 96.413), control1: CGPoint(x: 84.7546, y: 136.131), control2: CGPoint(x: 140.767, y: 111.689))
        path.addCurve(to: CGPoint(x: 209, y: 94.3762), control1: CGPoint(x: 180.485, y: 79.1001), control2: CGPoint(x: 196.779, y: 95.3946))
        return path.applying(CGAffineTransform(a: 0.34 * scale, b: 0, c: 0,
                                             d: 0.34 * scale, tx: -10.84 * scale, ty: -6.41998 * scale))
    }
}

struct OriginBadge: View {
    @Environment(\.semaAccent) private var accent
    let series: MarketSeries
    var body: some View {
        Text(series.isDemo ? "Démo" : series.sourceURL?.host == "webstat.banque-france.fr" ? "BdF" : "BCE")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(series.isDemo ? Color.secondary : accent)
    }
}

struct Surface<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(26)
            .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: SemaTheme.corner))
            .modifier(SemaElevation())
    }
}

/// A small contact shadow anchors the surface; a softer shadow separates its plane.
struct SemaElevation: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.16 : 0.04), radius: 2, x: 0, y: 1)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.20 : 0.06), radius: 16, x: 0, y: 6)
    }
}

struct SemaPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.99 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.85), value: configuration.isPressed)
    }
}
