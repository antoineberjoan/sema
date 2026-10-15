import AppKit
import SwiftUI
import MarketCore

@MainActor
enum SemaTheme {
    static let accent = Color(nsColor: NSColor(name: "SemaAccent") { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(srgbRed: 154 / 255, green: 208 / 255, blue: 194 / 255, alpha: 1)
        }
        return NSColor(srgbRed: 31 / 255, green: 111 / 255, blue: 115 / 255, alpha: 1)
    })
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let background = Color(nsColor: .windowBackgroundColor)
    static let separator = Color(nsColor: .separatorColor).opacity(0.5)
    static let corner: CGFloat = 16
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
    var size: CGFloat = 30
    var body: some View {
        SemaSymbol()
            .foregroundStyle(SemaTheme.accent)
            .padding(size * 0.08)
            .frame(width: size, height: size)
            .background(SemaTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: size * 0.28))
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
                    .stroke(style: StrokeStyle(lineWidth: 8 * scale, lineCap: .round, lineJoin: .round))
                Circle().frame(width: 8 * scale, height: 8 * scale)
                    .position(x: 49 * scale, y: 14 * scale)
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
        path.move(to: CGPoint(x: 37, y: 14))
        path.addLine(to: CGPoint(x: 27, y: 14))
        path.addCurve(to: CGPoint(x: 16, y: 23.5), control1: CGPoint(x: 20.4, y: 14), control2: CGPoint(x: 16, y: 18.1))
        path.addCurve(to: CGPoint(x: 27, y: 33), control1: CGPoint(x: 16, y: 29), control2: CGPoint(x: 20.4, y: 33))
        path.addLine(to: CGPoint(x: 37, y: 33))
        path.addCurve(to: CGPoint(x: 48, y: 42.5), control1: CGPoint(x: 43.6, y: 33), control2: CGPoint(x: 48, y: 37.1))
        path.addCurve(to: CGPoint(x: 37, y: 52), control1: CGPoint(x: 48, y: 48), control2: CGPoint(x: 43.6, y: 52))
        path.addLine(to: CGPoint(x: 21, y: 52))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

struct OriginBadge: View {
    let series: MarketSeries
    var body: some View {
        Text(series.isDemo ? "Démo" : "BCE")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(series.isDemo ? Color.secondary : SemaTheme.accent)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(series.isDemo ? Color.secondary.opacity(0.08) : SemaTheme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 5))
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
