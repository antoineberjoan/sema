// Déplie ou replie une section en cliquant sur toute sa ligne, pas seulement sur la flèche.
// @documentation https://developer.apple.com/documentation/swiftui/disclosuregroupstyle
// @decision docs/decisions/2026-11-12-composant-row-disclosure-style.md
import SemaDesign
import SwiftUI

struct RowDisclosureStyle: DisclosureGroupStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: DesignLayout.rowDisclosureContentSpacing) {
            Button {
                withAnimation(reduceMotion ? nil : .timingCurve(DesignEase.out, duration: DesignDuration.rowDisclosureDuration)) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(spacing: DesignLayout.rowDisclosureSpacing) {
                    Image(systemName: "chevron.right").typeRole(.caption).fontWeight(.semibold)
                        .rotationEffect(.degrees(configuration.isExpanded ? DesignMeasure.disclosureExpandedAngle : 0))
                        .frame(width: DesignLayout.rowDisclosureChevronWidth).accessibilityHidden(true)
                    configuration.label
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(configuration.isExpanded ? "Déplié" : "Replié")
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}
