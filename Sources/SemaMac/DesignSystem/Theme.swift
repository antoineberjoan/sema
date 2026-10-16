import AppKit
import SwiftUI
import MarketCore

enum SemaPalette: String, CaseIterable, Identifiable, Sendable {
    case teal, mint, lavender, sky, polar, graphite
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
    static func swatch(_ hex: UInt32) -> Color { Color(nsColor: nsColor(hex)) }
    private static func nsColor(_ hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}

private struct SemaAccentKey: EnvironmentKey {
    static let defaultValue: Color = SemaPalette.teal.accent
}

extension EnvironmentValues {
    var semaAccent: Color {
        get { self[SemaAccentKey.self] }
        set { self[SemaAccentKey.self] = newValue }
    }
}

@MainActor
enum SemaTheme {
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let background = Color(nsColor: .windowBackgroundColor)
    static let separator = Color(nsColor: .separatorColor).opacity(0.5)
    static let corner: CGFloat = 16

    static let menuBarIcon: NSImage = {
        let renderer = ImageRenderer(content: SemaSymbol().foregroundStyle(.black).frame(width: 18, height: 18))
        renderer.scale = 2
        let image = renderer.nsImage ?? NSImage(systemSymbolName: "waveform.path", accessibilityDescription: "Sema")!
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
        return series.unit == .percent || series.unit == .eur ? n + " " + series.unit.symbol : n
    }

    static func change(_ series: MarketSeries, period: HistoryPeriod) -> String {
        guard let delta = series.change(for: period) else { return "Historique insuffisant" }
        return number(delta, digits: 2, signed: true) + (series.unit == .percent ? " pt" : " %")
    }

    static func date(_ date: Date?) -> String {
        guard let date else { return "Date inconnue" }
        return date.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "fr_FR")))
    }

    static func double(_ value: Decimal) -> Double { NSDecimalNumber(decimal: value).doubleValue }
}

struct SemaMark: View {
    @Environment(\.semaAccent) private var accent
    var size: CGFloat = 30
    var body: some View {
        SemaSymbol()
            .foregroundStyle(accent)
            .padding(size * 0.08)
            .frame(width: size, height: size)
            .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: size * 0.28))
            .accessibilityHidden(true)
    }
}

/// Original Sema symbol, also supplied as editable SVG in Resources/Brand.
struct SemaSymbol: View {
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let scale = side / 64
            ZStack {
                SemaSignalPath()
                    .stroke(style: StrokeStyle(lineWidth: 7 * scale, lineCap: .round, lineJoin: .round))
                Circle().frame(width: 10 * scale, height: 10 * scale)
                    .position(x: 32 * scale, y: 32 * scale)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

private struct SemaSignalPath: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 64
        var path = Path()
        path.move(to: CGPoint(x: 29, y: 17))
        path.addLine(to: CGPoint(x: 23, y: 17))
        path.addCurve(to: CGPoint(x: 17, y: 23), control1: CGPoint(x: 19.7, y: 17), control2: CGPoint(x: 17, y: 19.7))
        path.addLine(to: CGPoint(x: 17, y: 29))
        path.move(to: CGPoint(x: 35, y: 47))
        path.addLine(to: CGPoint(x: 41, y: 47))
        path.addCurve(to: CGPoint(x: 47, y: 41), control1: CGPoint(x: 44.3, y: 47), control2: CGPoint(x: 47, y: 44.3))
        path.addLine(to: CGPoint(x: 47, y: 35))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

struct OriginBadge: View {
    @Environment(\.semaAccent) private var accent
    let series: MarketSeries
    var body: some View {
        Text(series.isDemo ? "Démo" : series.sourceURL?.host == "webstat.banque-france.fr" ? "BdF" : "BCE")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(series.isDemo ? Color.secondary : accent)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(series.isDemo ? Color.secondary.opacity(0.08) : accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 5))
    }
}

struct Surface<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(20)
            .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: SemaTheme.corner))
            .overlay(RoundedRectangle(cornerRadius: SemaTheme.corner).strokeBorder(SemaTheme.separator, lineWidth: 0.5))
    }
}
