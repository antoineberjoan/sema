// Applique palette, apparence, période partagée, position et verre du bandeau, et le sens d’affichage des parités.
import AppKit
import MarketCore
import SemaDesign

extension AppStore {
    var palette: DesignPalette { DesignPalette(rawValue: preferences.themeID ?? "") ?? .brand }

    var appearance: Appearance { Appearance(rawValue: preferences.appearanceID ?? "") ?? .system }

    var ribbonPosition: MenuRibbonPosition { MenuRibbonPosition(rawValue: preferences.ribbonPositionID ?? "") ?? .top }

    var ribbonGlass: RibbonGlassPreferences { preferences.ribbonGlass ?? .standard }

    func setPalette(_ palette: DesignPalette) { mutatePreferences { $0.themeID = palette.rawValue } }

    func setAppearance(_ appearance: Appearance) {
        guard mutatePreferences({ $0.appearanceID = appearance.rawValue }) else { return }
        NSApplication.shared.appearance = appearance.nativeAppearance
    }

    func setRibbonPosition(_ position: MenuRibbonPosition) { mutatePreferences { $0.ribbonPositionID = position.rawValue } }
    /// Une période pour le hub et le bandeau, gardée d’un lancement à l’autre.
    var period: HistoryPeriod { HistoryPeriod(rawValue: preferences.periodID ?? "") ?? .year }
    func setPeriod(_ period: HistoryPeriod) { mutatePreferences { $0.periodID = period.rawValue } }
    /// Une série trop courte pour la période choisie montre tout son historique, sans changer le choix partagé.
    func period(for series: MarketSeries) -> HistoryPeriod { series.supports(period) ? period : .all }

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
