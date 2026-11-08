// Vérifie la lecture des réponses FRED, leurs unités et l’absence de clé dans les requêtes construites.
import Foundation
import Testing
@testable import MarketCore

struct FREDClientTests {
    private let release = StatisticalDataset(source: .fred, code: "200", agency: "FRED", version: "1", title: "Cboe Market Statistics", detail: "")
    private let now = ISO8601DateFormatter().date(from: "2026-11-08T12:00:00Z")!

    private func metadata(_ id: String, title: String, units: String, frequency: String = "D") -> Data {
        Data(#"{"seriess":[{"id":"\#(id)","title":"\#(title)","units":"\#(units)","units_short":"Index","frequency_short":"\#(frequency)","notes":"Note"}]}"#.utf8)
    }
    private let observations = Data(#"{"observations":[{"date":"2026-11-03","value":"16.20"},{"date":"2026-11-04","value":"."},{"date":"2026-11-05","value":"28.40"}]}"#.utf8)

    @Test func releasesAndTheirSeriesBecomeTheCatalogue() throws {
        let releases = Data(#"{"releases":[{"id":18,"name":"H.15 Selected Interest Rates","notes":"Taux"},{"id":200,"name":"Cboe Market Statistics"}]}"#.utf8)
        let datasets = try StatisticalClient.fredDatasets(releases)
        #expect(datasets.map(\.code) == ["200", "18"])
        let series = Data(#"{"seriess":[{"id":"VIXCLS","title":"CBOE Volatility Index: VIX","units_short":"Index","frequency_short":"D"}]}"#.utf8)
        #expect(try StatisticalClient.fredSeriesCodes(series) == [.init(id: "VIXCLS", title: "CBOE Volatility Index: VIX · Index · D")])
    }

    @Test func indexSeriesSkipMissingValuesAndCompareInPercent() throws {
        let value = try StatisticalClient.fredSeries(observations: observations, metadata: metadata("VIXCLS", title: "CBOE Volatility Index: VIX", units: "Index"),
                                                     dataset: release, key: "VIXCLS", now: now)
        #expect(value.observations.map(\.value) == [Decimal(string: "16.20")!, Decimal(string: "28.40")!])
        #expect(value.unit == .index)
        #expect(value.variationConvention == .relativePercent)
        #expect(value.canAlert)
        #expect(value.frequency == .businessDaily)
    }

    @Test func percentSeriesUsePointsAndOtherUnitsKeepTheirLabel() throws {
        let rate = try StatisticalClient.fredSeries(observations: observations, metadata: metadata("DGS10", title: "Treasury 10Y", units: "Percent"),
                                                    dataset: release, key: "DGS10", now: now)
        #expect(rate.variationConvention == .points)
        let billions = StatisticalClient.fredUnit("Billions of U.S. Dollars")
        #expect(billions.code == "USD" && billions.multiplier == "9")
        #expect(StatisticalClient.fredUnit("Thousands of Persons").code == "Thousands of Persons")
        #expect(throws: StatisticalClient.ClientError.self) {
            try StatisticalClient.fredSeries(observations: observations, metadata: metadata("OTHER", title: "Autre", units: "Index"),
                                             dataset: release, key: "VIXCLS", now: now)
        }
    }

    @Test func builtRequestsNeverContainTheKey() throws {
        let observationsRequest = try StatisticalClient.observationsRequest(dataset: release, key: "VIXCLS", now: now)
        for request in [StatisticalClient.catalogueRequest(.fred), StatisticalClient.fredReleaseSeriesRequest(release),
                        StatisticalClient.fredSeriesRequest(key: "VIXCLS"), observationsRequest] {
            let address = request.url?.absoluteString ?? ""
            #expect(address.hasPrefix(StatisticalSource.fred.baseURL))
            #expect(!address.contains("api_key"))
        }
        #expect(observationsRequest.url?.absoluteString.contains("observation_start=") == true)
    }
}
