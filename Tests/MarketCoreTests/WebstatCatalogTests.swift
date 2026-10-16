import Foundation
import Testing
@testable import MarketCore

struct WebstatCatalogTests {
    private func descriptor(_ extra: [String: WebstatValue] = [:]) throws -> WebstatSeriesDescriptor {
        let raw: [String: WebstatValue] = [
            "series_key": .string("TEST.Q.FR.A"), "dataset_id": .string("TEST"),
            "title_fr": .string("Repère d’essai"), "title_long_fr": .string("Définition officielle"),
            "unit": .string("EUR"), "unit_mult": .string("6"), "freq": .string("Q"),
            "decimals": .string("3"), "first_time_period_date": .string("1990-03-31"),
            "series_dimensions_and_values": .string("{\"REF_AREA\":\"FR\",\"CURRENCY\":\"EUR\"}")]
        return try WebstatSeriesDescriptor(raw: raw.merging(extra, uniquingKeysWith: { _, new in new }))
    }

    @Test func sourceScaleIsDisplayedWithoutChangingTheValue() throws {
        let value = try descriptor()
        #expect(value.unit == .eur)
        #expect(value.displayUnit == "millions · €")
        #expect(value.frequency == .quarterly)
        #expect(value.canAlert)
        #expect(value.variation == .unavailable)
        let series = value.series(observations: [.init(date: .now, value: Decimal(string: "120.123")!)])
        #expect(series.latest?.value == Decimal(string: "120.123"))
        #expect(series.fractionDigits == 3)
        #expect(value.currency == "EUR")
        #expect(value.area == "FR")
    }

    @Test func catalogueEndDateIncludesTheFirstQuarterObservation() throws {
        let value = try descriptor()
        #expect(value.firstObservationStart == WebstatSeriesDescriptor.date("1990-01-01"))
        let monthly = try descriptor(["freq": .string("M"), "first_time_period_date": .string("1980-01-31")])
        #expect(monthly.firstObservationStart == WebstatSeriesDescriptor.date("1980-01-01"))
        let annual = try descriptor(["freq": .string("A"), "first_time_period_date": .string("1980-12-31")])
        #expect(annual.firstObservationStart == WebstatSeriesDescriptor.date("1980-01-01"))
    }

    @Test func unknownMetadataIsPreservedAndDoesNotInventPercentOrDaily() throws {
        let value = try descriptor(["unit": .string("UNRECOGNIZED"), "freq": .string("X"), "unit_mult": .null,
                                    "custom": .object(["values": .array([.number(1), .null])])])
        #expect(value.unit == .unknown)
        #expect(value.frequency == .unknown)
        #expect(!value.canAlert)
        #expect(value.variation == .unavailable)
        #expect(value.displayUnit == "Unité UNRECOGNIZED")
        #expect(try JSONDecoder().decode(WebstatSeriesDescriptor.self, from: JSONEncoder().encode(value)) == value)
    }

    @Test func rebasingOrScaleChangesCannotBeSplicedIntoTheOldCurve() throws {
        let initial = try descriptor(["unit": .string("IX"), "unit_mult": .string("0"),
            "series_attributes_and_values": .string("{\"UNIT_INDEX_BASE\":\"2015 = 100\"}")])
        let rebased = try descriptor(["unit": .string("IX"), "unit_mult": .string("0"),
            "series_attributes_and_values": .string("{\"UNIT_INDEX_BASE\":\"2025 = 100\"}")])
        #expect(!initial.usesSameMeasurement(as: rebased))
        let millions = try descriptor()
        let billions = try descriptor(["unit_mult": .string("9")])
        #expect(!millions.usesSameMeasurement(as: billions))
        #expect(initial.usesSameMeasurement(as: initial.resolving(labels: ["unit": "Indice"])))
    }

    @Test func sourceCodeLabelsAllowGenericAbsoluteThresholds() throws {
        let value = try descriptor(["unit": .string("NBRE"), "unit_mult": .string("0")])
            .resolving(labels: ["unit": "Nombre", "source_agency": "Banque de France"])
        #expect(value.canAlert)
        #expect(value.displayUnit == "Nombre")
        #expect(value.producer == "Banque de France")
        #expect(value.variation == .unavailable)
        #expect(!(try descriptor(["unit": .string("_Z")]).resolving(labels: ["unit": "Non applicable"])).canAlert)
        #expect(!(try descriptor(["unit": .string("_X")]).resolving(labels: ["unit": "Non spécifié"])).canAlert)
    }

    @Test func metadataFallsBackToOfficialDimensionsAndAttributes() throws {
        let value = try descriptor(["freq": .null, "unit": .null, "unit_mult": .null, "decimals": .null,
            "series_dimensions_and_values": .string("{\"FREQ\":\"A\",\"REF_AREA\":\"FR\"}"),
            "series_attributes_and_values": .string("{\"UNIT\":\"IX\",\"UNIT_MULT\":\"0\",\"DECIMALS\":\"2\",\"UNIT_INDEX_BASE\":\"2025 = 100\"}")])
        #expect(value.unit == .index)
        #expect(value.frequency == .yearly)
        #expect(value.decimals == 2)
        #expect(value.canAlert)
        #expect(value.attributes["UNIT_INDEX_BASE"] == "2025 = 100")
    }

    @Test func negativeAndZeroValuesRemainAvailableWithoutRelativeVariation() throws {
        let value = try descriptor()
        let series = value.series(observations: [.init(date: Date(timeIntervalSince1970: 0), value: -10), .init(date: .now, value: 0)])
        #expect(series.observations.map(\.value) == [-10, 0])
        #expect(series.change(for: .all) == nil)
        let rate = try descriptor(["unit": .string("PC"), "unit_mult": .string("0")]).series(observations: series.observations)
        #expect(rate.change(for: .all) == 10)
    }

    @Test func searchEscapesLiteralsAndKeepsSecretsOutOfURL() throws {
        let request = try WebstatClient.searchRequest(apiKey: "fixture-secret", search: .init(query: "l'immobilier \\ test", datasetID: "MIR1", area: "FR", frequency: "Q"), offset: 50)
        let url = try #require(request.url)
        let parameters = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let filter = try #require(parameters.first { $0.name == "where" }?.value)
        #expect(filter.contains("l\\'immobilier \\\\ test"))
        #expect(filter.contains("dataset_id = 'MIR1'"))
        #expect(parameters.first { $0.name == "offset" }?.value == "50")
        #expect(!url.absoluteString.contains("fixture-secret"))
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Apikey fixture-secret")
        #expect(throws: (any Error).self) { _ = try WebstatClient.request(table: "https://evil.invalid", apiKey: "key", parameters: []) }
    }

    @Test func exactCodeSearchAndPaginationAreExplicit() throws {
        let request = try WebstatClient.searchRequest(apiKey: "key", search: .init(query: "HICP.M.FR.N.000000.4D0.INX"))
        let filter = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "where" }?.value
        #expect(filter == "series_key = 'HICP.M.FR.N.000000.4D0.INX'")
        let data = Data("{\"total_count\":3,\"results\":[{\"series_key\":\"TEST.M.FR\",\"unit\":\"IX\"}]}".utf8)
        let page = try WebstatClient.parseSeriesPage(data, offset: 1)
        #expect(page.total == 3)
        #expect(page.hasMore)
        #expect(page.items[0].unit == .index)
    }

    @Test func observationsKeepSourcePeriodsAndNewestRevisionWithMissingValuesExcluded() throws {
        let data = Data("""
        [{"series_key":"TEST.Q.FR.A","time_period_start":"2026-01-01","time_period_end":"2026-03-31","obs_value":-1.25,"updated_at":"2026-04-02T10:00:00Z","obs_status":"A"},
         {"series_key":"TEST.Q.FR.A","time_period_start":"2026-01-01","time_period_end":"2026-03-31","obs_value":-1.4,"updated_at":"2026-04-01T10:00:00Z","obs_status":"E"},
         {"series_key":"TEST.Q.FR.A","time_period_start":"2026-04-01","time_period_end":"2026-06-30","obs_value":null,"obs_status":"M"},
         {"series_key":"OTHER.M.FR","time_period_start":"2026-04-01","time_period_end":"2026-04-30","obs_value":999}]
        """.utf8)
        let points = try WebstatClient.parseObservations(data, expectedKey: "TEST.Q.FR.A", now: Date(timeIntervalSince1970: 1_800_000_000))
        let value = try descriptor().series(observations: points)
        #expect(value.observations.count == 1)
        #expect(value.latest?.value == Decimal(string: "-1.25"))
        #expect(value.latest?.periodEnd == WebstatSeriesDescriptor.date("2026-03-31"))
    }

    @Test func versionOneMigrationPreservesAlertIdentityCheckpointAndLegacyFunds() throws {
        let rule = AlertRule(seriesID: "fr10", direction: .rise, threshold: 3, condition: .level, lastEvaluatedAt: Date(timeIntervalSince1970: 42))
        var legacy = AppPreferences(favoriteIDs: ["fr10", "fund-i-eur"], alerts: [rule])
        legacy.schemaVersion = 1
        let migrated = try legacy.migrated()
        #expect(migrated.schemaVersion == 2)
        #expect(migrated.favoriteIDs.contains(WebstatClient.canonicalID("fr10")))
        #expect(migrated.favoriteIDs.contains("fund-i-eur"))
        #expect(migrated.alerts[0].id == rule.id)
        #expect(migrated.alerts[0].lastEvaluatedAt == rule.lastEvaluatedAt)
        #expect(migrated.alerts[0].seriesID == WebstatClient.canonicalID("fr10"))
        #expect(migrated.onboardingCompleted == true)
    }

    @Test func versionTwoKeepsEmptyAndDeduplicatesCanonicalSelection() throws {
        let empty = AppPreferences(followedSeriesIDs: [])
        #expect(try JSONDecoder().decode(AppPreferences.self, from: JSONEncoder().encode(empty)).followedSeriesIDs.isEmpty)
        let duplicate = AppPreferences(followedSeriesIDs: ["fr10", WebstatClient.canonicalID("fr10"), "eurusd"])
        #expect(try duplicate.migrated().followedSeriesIDs == [WebstatClient.canonicalID("fr10"), WebstatClient.canonicalID("eurusd")])
    }

    @Test func migrationIsAtomicAndKeepsOriginalFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-migrate-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("preferences.json")
        let old = Data("{\"schemaVersion\":1,\"favoriteIDs\":[\"eurusd\"],\"alerts\":[],\"notificationsEnabled\":false}".utf8)
        try old.write(to: file)
        let store = PreferencesStore(fileURL: file)
        let migrated = try store.load()
        #expect(migrated.followedSeriesIDs.count == 13)
        #expect(try Data(contentsOf: file.appendingPathExtension("v1-backup")) == old)
        #expect(try store.load() == migrated)
    }
}
