// Pastille de l’écart à l’habituel : sa teinte s’intensifie avec le multiple, sans jamais coder hausse ou baisse.
// @documentation aucune
// @decision docs/decisions/2026-11-12-composant-move-badge.md
import SemaDesign
import SwiftUI
import MarketCore

struct MoveBadge: View {
    /// Five intensity zones of the brand teal: below 1×, 1–2×, 2–3×, 3–5×, above 5×.
    private static let zones: [(limit: Double, opacity: Double)] = [(1, 0), (2, 0.25), (3, 0.55), (5, 1), (.infinity, 1)]
    @Environment(\.palette) private var palette
    private var accent: Color { DesignColor.accent(palette) }
    let ratio: Double
    var prefix = ""
    var suffix = ""

    private var zone: Int { Self.zones.firstIndex { ratio < $0.limit } ?? Self.zones.count - 1 }

    var body: some View {
        Text(prefix + MarketFormat.ratio(ratio) + suffix)
            .typeRole(.tag).fontWeight(zone >= 2 ? .medium : .regular).monospacedDigit()
            .foregroundStyle(textColor)
            .padding(.horizontal, DesignSpace.markInsetInline).padding(.vertical, DesignSpace.markInset)
            .background(background, in: RoundedRectangle(cornerRadius: DesignRadius.mark))
            .accessibilityLabel(MarketFormat.ratio(ratio) + " la variation habituelle")
    }

    /// The same fill on an opaque page and on a glass card: the calmest zone is the glass-rest opacity of the text color.
    private var background: Color {
        switch zone {
        case 0: DesignColor.text.opacity(DesignOpacity.glassRest)
        case 4: DesignColor.text
        default: accent.opacity(Self.zones[zone].opacity)
        }
    }

    /// Dark text on the two strongest zones: the accent plate takes the on-accent text, the full plate takes the page color.
    private var textColor: Color {
        switch zone {
        case 0, 1, 2: DesignColor.text
        case 3: DesignColor.onAccent
        default: DesignColor.background
        }
    }
}
