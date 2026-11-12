// Vérifie le sens des lectures économiques, leur horizon et le refus des mesures non identifiées.
import Foundation
import Testing
@testable import MarketCore

struct SeriesExplanationTests {
    private func explain(_ series: MarketSeries, period: HistoryPeriod = .all, inverted: Bool = false) -> SeriesExplanation? {
        SeriesExplanation(series: series, period: period, inverted: inverted,
            formatNumber: { value, _ in NSDecimalNumber(decimal: value).stringValue })
    }

    private func points(_ values: [Decimal]) -> [MarketObservation] {
        values.enumerated().map { index, value in
            MarketObservation(date: Date(timeIntervalSince1970: 1_700_000_000 + Double(index) * 86_400), value: value)
        }
    }

    private func rate(_ id: String, values: [Decimal], unit: String = "PC", multiplier: String = "0",
                      frequency: String? = nil, definition: String = "Définition du fournisseur") throws -> MarketSeries {
        let key = WebstatClient.canonicalID(id)
        return try WebstatSeriesDescriptor(raw: [
            "series_key": .string(key), "dataset_id": .string(String(key.split(separator: ".")[0])),
            "freq": .string(frequency ?? String(key.split(separator: ".")[1])),
            "unit": .string(unit), "unit_mult": .string(multiplier), "decimals": .string("2"),
            "source_agency": .string("4F0"), "title_fr": .string("Titre officiel"),
            "title_long_fr": .string(definition)
        ]).series(observations: points(values))
    }

    @Test func quotationAndInverseKeepTheCorrectPurchasingDirection() throws {
        let series = try rate("eurusd", values: [Decimal(string: "1.10")!, Decimal(string: "1.21")!], unit: "USD")
        let original = series
        let direct = try #require(explain(series))
        #expect(direct.definition.contains("USD correspondent à 1 EUR"))
        #expect(direct.reading?.contains("EUR s’est apprécié face à USD") == true)
        #expect(direct.implication?.contains("prix fixe en USD, le coût en EUR diminue") == true)
        let inverse = try #require(explain(series, inverted: true))
        #expect(inverse.definition.contains("EUR correspondent à 1 USD"))
        #expect(inverse.reading?.contains("USD s’est déprécié face à EUR") == true)
        #expect(inverse.implication?.contains("prix fixe en EUR, le coût en USD augmente") == true)
        #expect(series == original)
    }

    @Test func quotationFallAndStabilityDoNotBecomeAppreciation() throws {
        let falling = try #require(explain(rate("eurusd", values: [Decimal(string: "1.21")!, Decimal(string: "1.10")!], unit: "USD")))
        #expect(falling.reading?.contains("EUR s’est déprécié") == true)
        #expect(falling.implication?.contains("coût en EUR augmente") == true)
        let flat = try #require(explain(rate("eurusd", values: [1, 1], unit: "USD")))
        #expect(flat.reading?.contains("inchangée") == true)
        #expect(flat.implication?.contains("identique") == true)
    }

    @Test func levelAloneAndPartialHistoryCannotJudgeCurrencyStrength() throws {
        let examples: [[Decimal]] = [[Decimal(string: "1.2")!], [1, Decimal(string: "1.2")!]]
        for values in examples {
            let reading = try #require(explain(rate("eurusd", values: values, unit: "USD"), period: .year))
            #expect(reading.reading?.contains("s’est apprécié") == false)
            #expect(reading.reading?.contains("s’est déprécié") == false)
            #expect(reading.implication?.contains("seul ne permet pas") == true)
        }
    }

    @Test func invalidExchangeRatesHaveNoEconomicReading() throws {
        for value in [Decimal.zero, Decimal(-1), Decimal.nan] {
            let reading = try #require(explain(rate("eurusd", values: [value], unit: "USD"), inverted: true))
            #expect(reading.reading == nil)
            #expect(reading.implication == nil)
        }
    }

    @Test func slowingPositiveInflationNeverMeansFallingPrices() throws {
        let reading = try #require(explain(rate("inflation", values: [3, 2])))
        #expect(reading.reading?.contains("2 % de plus qu’un an auparavant") == true)
        #expect(reading.reading?.contains("ralentit ; leur niveau reste plus élevé qu’un an auparavant") == true)
        #expect(reading.implication?.contains("revenus ne suivent pas") == true)
    }

    @Test func negativeInflationAndCrossingZeroKeepTheirMeaning() throws {
        let falling = try #require(explain(rate("inflation", values: [-1, -2])))
        #expect(falling.reading?.contains("2 % de moins qu’un an auparavant") == true)
        #expect(falling.reading?.contains("recul annuel des prix s’accentue") == true)
        let slowingFall = try #require(explain(rate("inflation", values: [-3, -2])))
        #expect(slowingFall.reading?.contains("recul annuel des prix ralentit") == true)
        let crossing = try #require(explain(rate("inflation", values: [-1, 2])))
        #expect(crossing.reading?.contains("2 % de plus qu’un an auparavant") == true)
        #expect(crossing.reading?.contains("taux a augmenté") == true)
        #expect(crossing.reading?.contains("hausse annuelle des prix s’accélère") == false)
        let flat = try #require(explain(rate("inflation", values: [0, 0])))
        #expect(flat.reading?.contains("niveau de prix du panier est inchangé") == true)
    }

    @Test func selectedChartHorizonNeverChangesTheAnnualInflationBasis() throws {
        let reading = try #require(explain(rate("inflation", values: [3, 2]), period: .quarter))
        #expect(reading.definition.contains("douze mois"))
        #expect(reading.reading?.contains("un an auparavant") == true)
        #expect(reading.reading?.contains("ralentit") == false)
    }

    @Test func currencyReadingUsesTheSelectedChartWindow() throws {
        let latest = Date(timeIntervalSince1970: 1_760_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = try #require(calendar.date(byAdding: .month, value: -12, to: latest))
        let monthly = latest.addingTimeInterval(-30 * 86_400)
        let series = try rate("eurusd", values: [], unit: "USD").replacing(observations: [
            .init(date: start, value: Decimal(string: "1.2")!),
            .init(date: monthly, value: 1),
            .init(date: latest, value: Decimal(string: "1.1")!)
        ])
        #expect(explain(series, period: .year)?.reading?.contains("EUR s’est déprécié") == true)
        #expect(explain(series, period: .quarter)?.reading?.contains("EUR s’est apprécié") == true)
    }

    @Test func anIndexOrChangedScaleNeverBecomesAnInflationPercentage() throws {
        for series in [try rate("inflation", values: [120], unit: "IX", definition: "Indice, base 100 en 2015."),
                       try rate("inflation", values: [120], multiplier: "3"),
                       try rate("inflation", values: [2], frequency: "Q")] {
            let reading = try #require(explain(series))
            #expect(reading.reading == nil)
            #expect(reading.implication == nil)
            #expect(!reading.definition.contains("sur douze mois"))
        }
    }

    @Test func ratesRemainLevelsRatherThanPercentageReturns() throws {
        let reading = try #require(explain(rate("ecb", values: [-1, 2])))
        #expect(reading.definition.contains("dépôts des banques"))
        #expect(reading.reading?.contains("taux publié est de 2 %") == true)
        #expect(reading.reading?.contains("taux a augmenté") == true)
        #expect(reading.implication?.contains("sans fixer à lui seul") == true)
        let bond = try #require(explain(rate("fr10", values: [3, 4])))
        #expect(bond.definition.contains("pas son coupon ni son prix"))
        #expect(bond.implication?.contains("obligations à taux fixe existantes") == true)
        let loan = try #require(explain(rate("mortgage-fr", values: [3, 4])))
        #expect(loan.definition.contains("ni un TAEG ni une offre bancaire"))
    }

    @Test func everyOtherKnownRateHasASpecificDefinition() throws {
        for id in ["estr", "livreta", "ldds", "lep", "inflation-euro"] {
            let reading = try #require(explain(rate(id, values: [2])))
            #expect(reading.definition != "Définition du fournisseur")
            #expect(reading.reading != nil)
        }
    }

    @Test func unknownMeasuresAreNotInvented() throws {
        let unknown = try rate("CUSTOM.M.FR.SERIES", values: [2])
        let fallback = try #require(explain(unknown))
        #expect(fallback.definition == "Définition du fournisseur")
        #expect(fallback.reading == nil)
        #expect(fallback.implication == nil)
        let noDefinition = MarketSeries(id: "X17", name: "Inflation", subtitle: "", category: .markets,
            unit: .percent, source: "Inconnue", observations: points([2]))
        #expect(explain(noDefinition) == nil)
    }
}
