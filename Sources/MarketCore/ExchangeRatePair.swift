// Reconnaît les paires vérifiées et projette leur cotation inverse uniquement pour l’affichage.
import Foundation

/// A verified ECB spot quotation, published as units of currency for one euro.
public struct ExchangeRatePair: Equatable, Sendable {
    public let currency: String
    public var id: String { "EUR/" + currency }
    public var publishedDescription: String { currency + " pour 1 EUR" }
    public var inverseDescription: String { "EUR pour 1 " + currency }
    public var publishedName: String { "Euro / " + currencyName }
    public var inverseName: String { currencyName + " / Euro" }
    private var currencyName: String {
        switch currency {
        case "USD": "Dollar"
        case "JPY": "Yen"
        case "CHF": "Franc suisse"
        case "GBP": "Livre sterling"
        default: currency
        }
    }

    public init?(_ series: MarketSeries) {
        let key: String
        if series.isDemo, series.descriptor == nil, series.statisticalDescriptor == nil {
            let canonical = WebstatClient.canonicalID(series.id)
            guard canonical.hasPrefix("EXR.") else { return nil }
            key = String(canonical.dropFirst(4))
        } else {
            guard let verified = SeriesEquivalence.referenceExchangeRateKey(series) else { return nil }
            key = String(verified.dropFirst("ECB:EXR:".count))
        }
        let parts = key.split(separator: ".").map(String.init)
        guard parts.count == 5, parts[2] == "EUR", parts[3] == "SP00", parts[4] == "A",
              parts[1] != "EUR", parts[1].count == 3 else { return nil }
        // An inverse display projection keeps the source ID, but is no longer the published demo quotation.
        guard !series.isDemo || series.unit.symbol == parts[1] else { return nil }
        currency = parts[1]
    }
}

extension MarketSeries {
    public var exchangeRatePair: ExchangeRatePair? { ExchangeRatePair(self) }
    public var canInvertExchangeRate: Bool {
        exchangeRatePair != nil && observations.allSatisfy { $0.value > 0 }
    }

    /// Display only: source metadata, cache, selection and alerts keep the published series.
    /// Every point is inverted before variations and chart bounds are calculated.
    public func invertedExchangeRateForDisplay() -> MarketSeries? {
        guard let pair = exchangeRatePair, canInvertExchangeRate else { return nil }
        var inverted: [MarketObservation] = []
        for point in observations {
            let value = 1 / point.value
            guard !value.isNaN, value > 0 else { return nil }
            inverted.append(MarketObservation(date: point.date, value: value,
                periodEnd: point.periodEnd, updatedAt: point.updatedAt, status: point.status))
        }
        let digits = (inverted.last?.value ?? 1) < Decimal(string: "0.1")! ? 6 : 4
        return MarketSeries(id: id, name: pair.inverseName,
            subtitle: pair.inverseDescription + " · lecture inversée", category: category, unit: .eur,
            fractionDigits: max(digits, fractionDigits), source: source, sourceURL: sourceURL,
            isDemo: isDemo, frequency: frequency, observations: inverted,
            syncedAt: syncedAt, hasCompleteHistory: hasCompleteHistory)
    }
}
