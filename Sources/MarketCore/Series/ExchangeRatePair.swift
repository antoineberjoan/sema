// Reconnaît les paires vérifiées et projette leur cotation inverse uniquement pour l’affichage.
import Foundation

/// A verified ECB spot quotation, published as units of currency for one euro.
public struct ExchangeRatePair: Equatable, Sendable {
    /// An inverted rate below this value needs more decimals to stay readable.
    static let smallRate = Decimal(string: "0.1")!
    static let smallRateDigits = 6
    static let rateDigits = 4
    public let currency: String
    public var id: String { "EUR/" + currency }
    public var publishedDescription: String { currency + " pour 1 EUR" }
    public var inverseDescription: String { "EUR pour 1 " + currency }
    public var inverseName: String {
        let name = switch currency {
        case "USD": "Dollar"
        case "JPY": "Yen"
        case "CHF": "Franc suisse"
        case "GBP": "Livre sterling"
        default: currency
        }
        return name + " / Euro"
    }

    public init?(_ series: MarketSeries) {
        let key: String
        if series.isDemo, series.descriptor == nil, series.statisticalDescriptor == nil {
            let canonical = WebstatClient.canonicalID(series.id)
            guard canonical.hasPrefix(SeriesEquivalence.webstatPrefix) else { return nil }
            key = String(canonical.dropFirst(SeriesEquivalence.webstatPrefix.count))
        } else {
            guard let verified = SeriesEquivalence.referenceExchangeRateKey(series) else { return nil }
            key = String(verified.dropFirst(SeriesEquivalence.referencePrefix.count))
        }
        guard let parts = SeriesEquivalence.spotRateParts(key), parts[1] != "EUR", parts[1].count == 3 else { return nil }
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
        let digits = (inverted.last?.value ?? 1) < ExchangeRatePair.smallRate ? ExchangeRatePair.smallRateDigits : ExchangeRatePair.rateDigits
        return MarketSeries(id: id, name: pair.inverseName,
            subtitle: pair.inverseDescription + " · lecture inversée", category: category, unit: .eur,
            fractionDigits: max(digits, fractionDigits), source: source, sourceURL: sourceURL,
            isDemo: isDemo, frequency: frequency, observations: inverted,
            syncedAt: syncedAt, hasCompleteHistory: hasCompleteHistory)
    }
}
