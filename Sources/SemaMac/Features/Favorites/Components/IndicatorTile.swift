// Tuile d'un repère épinglé : son nom, sa valeur, sa variation du mois et ses actions.
import MarketCore
import SemaDesign
import SwiftUI

struct IndicatorTile: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    let series: MarketSeries
    let action: () -> Void

    /// Les boutons de fin flottent sur la tuile : le titre laisse la place à chacun.
    private var actionCount: Int { series.exchangeRatePair == nil ? 1 : 2 }

    var body: some View {
        let displayed = store.displayedSeries(series)
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                    HStack(spacing: DesignIcon.gap) {
                        Text(MarketFormat.name(displayed)).typeRole(.heading).lineLimit(1)
                        if !store.isSourceEnabled(for: series.id) {
                            Image(systemName: "pause.circle").foregroundStyle(DesignColor.textMuted).help("Source désactivée · historique conservé")
                        }
                    }
                    .padding(.trailing, CGFloat(actionCount) * DesignIcon.buttonSize)
                    HStack(alignment: .firstTextBaseline) {
                        Text(MarketFormat.value(displayed))
                            .typeRole(.figure)
                            .lineLimit(1).minimumScaleFactor(CGFloat(DesignMeasure.indicatorTileValueMinimumScale))
                        Spacer(minLength: DesignSpace.fieldGap)
                        Text(MarketFormat.change(displayed, period: .month))
                            .typeRole(.caption).monospacedDigit().foregroundStyle(DesignColor.textMuted)
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(DesignColor.text)
                .padding(DesignSpace.cardInset)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isHovered ? DesignColor.hover : DesignColor.surface, in: RoundedRectangle(cornerRadius: DesignRadius.block, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: DesignRadius.block, style: .continuous))
            }
            .buttonStyle(PressStyle())
            .accessibilityLabel("\(MarketFormat.name(displayed)), \(MarketFormat.value(displayed))")
            HStack(spacing: 0) {
                ExchangeDirectionButton(series: series)
                FavoriteButton(seriesID: series.id, seriesName: MarketFormat.name(displayed))
            }.padding(DesignSpace.cornerButtonInset)
        }
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .timingCurve(DesignEase.hover, duration: DesignDuration.fast), value: isHovered)
    }
}
