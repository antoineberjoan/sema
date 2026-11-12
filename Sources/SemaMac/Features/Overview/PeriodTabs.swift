// Onglets texte de la période, alignés sur le titre du repère : un clic suffit, le bandeau suit le même choix.
import SemaDesign
import SwiftUI
import MarketCore

struct PeriodTabs: View {
    private static let indicatorHeight: CGFloat = 2
    @Environment(\.palette) private var palette
    private var accent: Color { DesignColor.accent(palette) }
    let periods: [HistoryPeriod]
    let selection: HistoryPeriod
    let select: (HistoryPeriod) -> Void

    var body: some View {
        HStack(spacing: Spacing.s16) {
            ForEach(periods) { period in
                let selected = period == selection
                Button { select(period) } label: {
                    Text(period.shortTitle)
                        .typeRole(.small).fontWeight(selected ? .semibold : .regular)
                        .foregroundStyle(selected ? Color.primary : Color.secondary)
                        .padding(.bottom, Spacing.s4)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(selected ? accent : .clear).frame(height: Self.indicatorHeight)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(period.title)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
                .help(period.title)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Période de l’historique")
    }
}
