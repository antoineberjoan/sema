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
        HStack(spacing: DesignSpace.itemGap) {
            ForEach(periods) { period in
                let isSelected = period == selection
                Button { select(period) } label: {
                    Text(period.shortTitle)
                        .typeRole(.small).fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? DesignColor.text : DesignColor.textMuted)
                        .padding(.bottom, DesignSpace.markInset)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(isSelected ? accent : .clear).frame(height: Self.indicatorHeight)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(period.title)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                .help(period.title)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Période de l’historique")
    }
}
