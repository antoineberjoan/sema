// Pastille de l’écart à l’habituel : sa teinte s’intensifie avec le multiple, sans jamais coder hausse ou baisse.
// @documentation aucune
// @decision docs/decisions/2026-11-12-composant-move-badge.md
import SemaDesign
import SwiftUI
import MarketCore

struct MoveBadge: View {
    /// Cinq zones d’intensité de la sarcelle de la marque : sous 1×, 1–2×, 2–3×, 3–5×, au-dessus de 5×.
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

    /// Le même remplissage sur une page opaque et sur une carte de verre : la zone la plus calme prend l’opacité « verre au repos » de la couleur du texte.
    private var background: Color {
        switch zone {
        case 0: DesignColor.text.opacity(DesignOpacity.glassRest)
        case 4: DesignColor.text
        default: accent.opacity(Self.zones[zone].opacity)
        }
    }

    /// Texte sombre sur les deux zones les plus fortes : la plaque d’accent prend le texte sur accent, la plaque pleine prend la couleur de la page.
    private var textColor: Color {
        switch zone {
        case 0, 1, 2: DesignColor.text
        case 3: DesignColor.onAccent
        default: DesignColor.background
        }
    }
}
