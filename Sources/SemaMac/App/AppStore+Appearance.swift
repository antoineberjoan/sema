// Applique palette, apparence, position et verre du bandeau, et le sens d’affichage des parités.
import AppKit
import MarketCore

extension AppStore {
    var palette: SemaPalette { SemaPalette(rawValue: preferences.themeID ?? "") ?? .graphite }

    var appearance: SemaAppearance { SemaAppearance(rawValue: preferences.appearanceID ?? "") ?? .system }

    var ribbonPosition: MenuRibbonPosition { MenuRibbonPosition(rawValue: preferences.ribbonPositionID ?? "") ?? .top }

    var ribbonGlass: RibbonGlassPreferences { preferences.ribbonGlass ?? .standard }

    func setPalette(_ palette: SemaPalette) { mutatePreferences { $0.themeID = palette.rawValue } }

    func setAppearance(_ appearance: SemaAppearance) {
        guard mutatePreferences({ $0.appearanceID = appearance.rawValue }) else { return }
        NSApplication.shared.appearance = appearance.nativeAppearance
    }

    func setRibbonPosition(_ position: MenuRibbonPosition) { mutatePreferences { $0.ribbonPositionID = position.rawValue } }

    func setRibbonGlass(_ glass: RibbonGlassPreferences) {
        guard glass != ribbonGlass else { return }
        mutatePreferences { $0.ribbonGlass = glass }
    }

    func isExchangeRateInverted(_ item: MarketSeries) -> Bool {
        guard let pair = item.exchangeRatePair else { return false }
        return (preferences.invertedCurrencyPairs ?? []).contains(pair.id)
    }

    func displayedSeries(_ item: MarketSeries) -> MarketSeries {
        guard isExchangeRateInverted(item) else { return item }
        if let cached = invertedExchangeRates[item.id], cached.source == item { return cached.display }
        guard let inverse = item.invertedExchangeRateForDisplay() else { return item }
        invertedExchangeRates[item.id] = (item, inverse)
        return inverse
    }

    func toggleExchangeRateDirection(_ item: MarketSeries) {
        guard let pair = item.exchangeRatePair, item.canInvertExchangeRate else { return }
        mutatePreferences { value in
            var inverted = value.invertedCurrencyPairs ?? []
            if inverted.contains(pair.id) { inverted.remove(pair.id) } else { inverted.insert(pair.id) }
            value.invertedCurrencyPairs = inverted
        }
    }
}
