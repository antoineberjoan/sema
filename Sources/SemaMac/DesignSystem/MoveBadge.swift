// Pastille de l’écart à l’habituel : sa teinte s’intensifie avec le multiple, sans jamais coder hausse ou baisse.
import SwiftUI
import MarketCore

struct MoveBadge: View {
    /// Five intensity zones of the brand teal: below 1×, 1–2×, 2–3×, 3–5×, above 5×.
    private static let zones: [(limit: Double, opacity: Double)] = [(1, 0), (2, 0.25), (3, 0.55), (5, 1), (.infinity, 1)]
    @Environment(\.semaAccent) private var accent
    let ratio: Double
    var suffix = ""

    private var zone: Int { Self.zones.firstIndex { ratio < $0.limit } ?? Self.zones.count - 1 }

    var body: some View {
        Text(MarketFormat.ratio(ratio) + suffix)
            .typeRole(.tag).fontWeight(zone >= 2 ? .medium : .regular).monospacedDigit()
            .foregroundStyle(zone >= 3 ? Color.white : Color.primary)
            .padding(.horizontal, Spacing.s6).padding(.vertical, Spacing.s2)
            .background(background, in: RoundedRectangle(cornerRadius: Radius.mark))
            .accessibilityLabel(MarketFormat.ratio(ratio) + " la variation habituelle")
    }

    private var background: Color {
        switch zone {
        case 0: Theme.quietFill
        case 4: Color.primary
        default: accent.opacity(Self.zones[zone].opacity)
        }
    }
}
