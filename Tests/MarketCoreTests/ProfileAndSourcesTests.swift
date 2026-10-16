import Foundation
import Testing
@testable import MarketCore

struct ProfileAndSourcesTests {
    @Test func olderPreferencesKeepEverySourceAvailable() throws {
        let original = AppPreferences(favoriteIDs: [], followedSeriesIDs: [], onboardingCompleted: true)
        let data = try JSONEncoder().encode(original)
        let raw = try JSONSerialization.jsonObject(with: data)
        var document = try #require(raw as? [String: Any])
        for key in ["profile", "disabledSourceIDs", "alertBaselineIDs"] { document.removeValue(forKey: key) }
        let restored = try JSONDecoder().decode(AppPreferences.self, from: JSONSerialization.data(withJSONObject: document)).migrated()
        #expect(restored.followedSeriesIDs.isEmpty)
        #expect(restored.profile == nil)
        for id in ["webstat"] + StatisticalSource.allCases.map(\.rawValue) { #expect(restored.isSourceEnabled(id)) }
    }

    @Test func localProfileAndSourcePausesSurviveAtomicSave() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = PreferencesStore(fileURL: directory.appendingPathComponent("preferences.json"))
        var value = AppPreferences(disabledSourceIDs: ["insee", "future-source"],
            profile: LocalProfile(firstName: " Élodie ", lastName: " Martin ", avatarJPEG: Data([1, 2, 3])))
        value.alertBaselineIDs = [UUID()]
        try file.save(value)
        let restored = try file.load()
        #expect(restored == value)
        #expect(restored.profile?.displayName == "Élodie Martin")
        #expect(restored.profile?.initials == "ÉM")
        #expect(!restored.isSourceEnabled("insee"))
        #expect(restored.isSourceEnabled("webstat"))
        #expect(restored.disabledSourceIDs?.contains("future-source") == true)
    }

    @Test func verifiedECBReferenceRateIsOneRepereAcrossAccessPoints() throws {
        let webstat = try webstatRate()
        let ecb = ecbRate()
        #expect(SeriesEquivalence.matches(webstat, ecb))
        #expect(SeriesEquivalence.unique([webstat, ecb]).map(\.id) == [webstat.id])
        #expect(SeriesEquivalence.unique([ecb, webstat]).map(\.id) == [ecb.id])
        #expect(SeriesEquivalence.accessPoints(for: webstat).map(\.sourceID) == ["webstat", "ecb"])
    }

    @Test func similarLabelsNeverMergeDifferentMeasurements() throws {
        let reference = try webstatRate()
        #expect(!SeriesEquivalence.matches(reference, ecbRate(key: "M.USD.EUR.SP00.A", frequency: "M")))
        #expect(!SeriesEquivalence.matches(reference, ecbRate(key: "D.JPY.EUR.SP00.A", unit: "JPY")))
        #expect(!SeriesEquivalence.matches(reference, ecbRate(multiplier: "3")))
        #expect(!SeriesEquivalence.matches(reference, ecbRate(producer: "UNKNOWN")))
        #expect(!SeriesEquivalence.matches(reference, ecbRate(version: "2.0")))
        let other = MarketSeries(id: "other", name: reference.name, subtitle: "", category: .markets,
            unit: .usd, source: "Autre", isDemo: false, observations: reference.observations)
        #expect(!SeriesEquivalence.matches(reference, other))
        #expect(SeriesEquivalence.accessPoints(for: other).isEmpty)
    }

    private func webstatRate() throws -> MarketSeries {
        try WebstatSeriesDescriptor(raw: ["series_key": .string("EXR.D.USD.EUR.SP00.A"),
            "dataset_id": .string("EXR"), "title_fr": .string("Dollar"), "source_agency": .string("4F0"),
            "freq": .string("D"), "unit": .string("USD"), "unit_mult": .string("0")]).series(observations: [])
    }
    private func ecbRate(key: String = "D.USD.EUR.SP00.A", frequency: String = "D", unit: String = "USD",
                         multiplier: String = "0", producer: String = "4F0", version: String = "1.0") -> MarketSeries {
        let dataset = StatisticalDataset(source: .ecb, code: "EXR", agency: "ECB", version: version, title: "Exchange rates", detail: "")
        return StatisticalSeriesDescriptor(dataset: dataset, key: key,
            dimensionIDs: ["FREQ", "CURRENCY", "CURRENCY_DENOM", "EXR_TYPE", "EXR_SUFFIX"],
            fields: ["FREQ": frequency, "UNIT": unit, "UNIT_MULT": multiplier, "SOURCE_AGENCY": producer], labels: [:])
            .series(observations: [])
    }
}
