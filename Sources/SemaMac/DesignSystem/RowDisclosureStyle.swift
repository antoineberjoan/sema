// Déplie ou replie une section en cliquant sur toute sa ligne, pas seulement sur la flèche.
import SwiftUI

struct RowDisclosureStyle: DisclosureGroupStyle {
    private static let spacing: CGFloat = 6
    private static let chevronWidth: CGFloat = 12
    private static let chevronFont = Font.caption.weight(.semibold)
    private static let contentSpacing: CGFloat = 8
    private static let duration = 0.18
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: Self.contentSpacing) {
            Button {
                withAnimation(reduceMotion ? nil : .easeOut(duration: Self.duration)) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Self.spacing) {
                    Image(systemName: "chevron.right").font(Self.chevronFont)
                        .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                        .frame(width: Self.chevronWidth).accessibilityHidden(true)
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
