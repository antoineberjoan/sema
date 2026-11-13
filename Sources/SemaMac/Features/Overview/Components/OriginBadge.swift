// Indique la provenance d’une série.
import SemaDesign
import SwiftUI
import MarketCore

struct OriginBadge: View {
    @Environment(\.palette) private var palette
    private var accent: Color { DesignColor.accent(palette) }
    let series: MarketSeries
    var body: some View {
        Text(series.originBadge)
            .typeRole(.overline)
            .foregroundStyle(accent)
    }
}
