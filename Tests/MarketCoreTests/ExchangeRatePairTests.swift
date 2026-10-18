// Vérifie l’inversion des cotations, les variations et le rejet des valeurs non inversibles.
import Foundation
import Testing
@testable import MarketCore

struct ExchangeRatePairTests {
    private let tolerance = Decimal(string: "0.000000000000000000000001")!

    @Test func inversionPreservesDatesAndSourceValues() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let point = MarketObservation(date: date, value: Decimal(string: "1.1642")!,
            periodEnd: date.addingTimeInterval(100), updatedAt: date.addingTimeInterval(200), status: "A")
        let original = try rate(points: [point])
        let encoded = try JSONEncoder().encode(original)
        let inverted = try #require(original.invertedExchangeRateForDisplay())
        #expect(inverted.name == "Dollar / Euro")
        #expect(inverted.subtitle == "EUR pour 1 USD · lecture inversée")
        #expect(inverted.unit == .eur)
        #expect(inverted.id == original.id)
        #expect(inverted.latest?.date == point.date)
        #expect(inverted.latest?.periodEnd == point.periodEnd)
        #expect(inverted.latest?.updatedAt == point.updatedAt)
        #expect(inverted.latest?.status == point.status)
        let value = try #require(inverted.latest?.value)
        #expect(abs(value * point.value - 1) < tolerance)
        #expect(original.latest?.value == point.value)
        let restored = try JSONDecoder().decode(MarketSeries.self, from: encoded)
        #expect(restored == original)
        #expect(original.descriptor?.unitCode == "USD")
    }

    @Test func inverseVariationIsRecalculatedRatherThanNegated() throws {
        let original = try rate(points: [
            MarketObservation(date: Date(timeIntervalSince1970: 1_700_000_000), value: Decimal(string: "1.10")!),
            MarketObservation(date: Date(timeIntervalSince1970: 1_700_086_400), value: Decimal(string: "1.21")!)
        ])
        let inverse = try #require(original.invertedExchangeRateForDisplay())
        let change = try #require(inverse.change(for: .all))
        #expect(original.change(for: .all) == 10)
        #expect(abs(change - (-Decimal(100) / 11)) < tolerance)
        #expect(change != -10)
    }

    @Test func onlyVerifiedSpotRatesExposeTheSwitch() throws {
        let webstat = try rate()
        let dataset = StatisticalDataset(source: .ecb, code: "EXR", agency: "ECB", version: "1.0", title: "Changes", detail: "")
        let ecb = StatisticalSeriesDescriptor(dataset: dataset, key: "D.USD.EUR.SP00.A",
            dimensionIDs: ["FREQ", "CURRENCY", "CURRENCY_DENOM", "EXR_TYPE", "EXR_SUFFIX"],
            fields: ["FREQ": "D", "UNIT": "USD", "UNIT_MULT": "0", "SOURCE_AGENCY": "4F0"], labels: [:])
            .series(observations: [])
        #expect(webstat.exchangeRatePair?.id == "EUR/USD")
        #expect(ecb.exchangeRatePair == webstat.exchangeRatePair)
        #expect(try rate(multiplier: "3").exchangeRatePair == nil)
        #expect(try rate(producer: "UNKNOWN").exchangeRatePair == nil)
        #expect(try rate(key: "EXR.D.USD.EUR.SP00.E").exchangeRatePair == nil)
        let nav = MarketSeries(id: "fund", name: "Euro / Dollar", subtitle: "", category: .funds,
            unit: .usd, source: "Fonds", isDemo: false, observations: [])
        #expect(nav.exchangeRatePair == nil)
        #expect(DemoCatalog.series().first { $0.id == "eurusd" }?.canInvertExchangeRate == true)
        #expect(DemoCatalog.series().first { $0.id == "fr10" }?.exchangeRatePair == nil)
    }

    @Test func invalidObservationsNeverProduceAnInfiniteQuote() throws {
        for value in [Decimal.zero, Decimal(-1), Decimal.nan] {
            let series = try rate(points: [MarketObservation(date: Date(), value: value)])
            #expect(!series.canInvertExchangeRate)
            #expect(series.invertedExchangeRateForDisplay() == nil)
        }
    }

    @Test func smallInverseQuotesKeepEnoughDisplayPrecision() throws {
        let series = try rate(key: "EXR.D.JPY.EUR.SP00.A", currency: "JPY", points: [
            MarketObservation(date: Date(), value: Decimal(string: "171.46")!)
        ])
        let inverse = try #require(series.invertedExchangeRateForDisplay())
        #expect(inverse.name == "Yen / Euro")
        #expect(inverse.fractionDigits >= 6)
        #expect((inverse.latest?.value ?? 0) < Decimal(string: "0.01")!)
        #expect((inverse.latest?.value ?? 0) > 0)
    }

    @Test func inverseDemoCannotBeRelabelledAsThePublishedQuotation() throws {
        let demo = try #require(DemoCatalog.series().first { $0.id == "eurjpy" })
        let inverse = try #require(demo.invertedExchangeRateForDisplay())
        #expect(demo.exchangeRatePair?.currency == "JPY")
        #expect(inverse.exchangeRatePair == nil)
        #expect(inverse.name == "Yen / Euro")
        #expect(inverse.displayUnit == "€")
    }

    @Test func directionPersistsWithoutChangingFavoritesOrAlerts() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-quote-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("preferences.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let previous = Data("""
        {"schemaVersion":2,"favoriteIDs":["eurusd"],"followedSeriesIDs":["eurusd"],"alerts":[],"notificationsEnabled":false}
        """.utf8)
        try previous.write(to: file)
        let store = PreferencesStore(fileURL: file)
        var preferences = try store.load()
        #expect(preferences.invertedCurrencyPairs == nil)
        let originalFile = try Data(contentsOf: file)
        #expect(originalFile == previous)
        preferences.alerts = [AlertRule(seriesID: WebstatClient.canonicalID("eurusd"), direction: .rise,
            threshold: Decimal(string: "1.2")!, condition: .level)]
        let favorites = preferences.favoriteIDs
        let selection = preferences.followedSeriesIDs
        let alerts = preferences.alerts
        preferences.invertedCurrencyPairs = ["EUR/USD"]
        try store.save(preferences)
        let restored = try store.load()
        #expect(restored.invertedCurrencyPairs == ["EUR/USD"])
        #expect(restored.favoriteIDs == favorites)
        #expect(restored.followedSeriesIDs == selection)
        #expect(restored.alerts == alerts)
    }

    private func rate(key: String = "EXR.D.USD.EUR.SP00.A", currency: String = "USD",
                      multiplier: String = "0", producer: String = "4F0", points: [MarketObservation] = []) throws -> MarketSeries {
        try WebstatSeriesDescriptor(raw: ["series_key": .string(key), "dataset_id": .string("EXR"),
            "title_fr": .string("Euro / " + currency), "source_agency": .string(producer), "freq": .string("D"),
            "unit": .string(currency), "unit_mult": .string(multiplier), "decimals": .string("4")])
            .series(observations: points)
    }
}
