// Inverse le sens d’affichage d’une parité de change.
import SwiftUI
import MarketCore

struct ExchangeDirectionButton: View {
    @Environment(AppStore.self) private var store
    @Environment(\.semaAccent) private var accent
    let series: MarketSeries

    var body: some View {
        if let pair = series.exchangeRatePair {
            let inverted = store.isExchangeRateInverted(series)
            let target = inverted ? pair.publishedDescription : pair.inverseDescription
            Button { store.toggleExchangeRateDirection(series) } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.callout).foregroundStyle(inverted ? accent : Color.secondary)
                    .frame(width: SemaTheme.iconButtonSize, height: SemaTheme.iconButtonSize).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!series.canInvertExchangeRate)
            .help(series.canInvertExchangeRate ? "Afficher " + target : "Inversion indisponible : les cours doivent être strictement positifs.")
            .accessibilityLabel("Inverser la paire · afficher " + target)
        }
    }
}
