// Indique la provenance d’une série ou son caractère de démonstration.
import SwiftUI
import MarketCore

struct OriginBadge: View {
    @Environment(\.semaAccent) private var accent
    let series: MarketSeries
    var body: some View {
        Text(series.isDemo ? "Démo" : series.originBadge)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(series.isDemo ? Color.secondary : accent)
    }
}
