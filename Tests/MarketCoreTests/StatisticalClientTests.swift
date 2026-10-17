// Vérifie les contrats de découverte et de décodage des fournisseurs publics.
import Foundation
import Testing
@testable import MarketCore

struct StatisticalClientTests {
    private let dataset = StatisticalDataset(source: .ecb, code: "UNLISTED", agency: "ECB", version: "1.0", title: "Un jeu nouveau", detail: "Définition officielle")
    private let structure = StatisticalStructure(dimensions: [
        .init(id: "FREQ", title: "Fréquence", position: 1, codes: []),
        .init(id: "REF_AREA", title: "Zone", position: 2, codes: [])
    ], labels: [:])

    private func data(unit: String = "PC", multiplier: String = "0", extra: String = "") -> Data {
        Data("""
        <GenericData><DataSet><Series><SeriesKey><Value id="FREQ" value="Q"/><Value id="REF_AREA" value="FR"/></SeriesKey>
        <Attributes><Value id="UNIT" value="\(unit)"/><Value id="UNIT_MULT" value="\(multiplier)"/><Value id="TITLE" value="Taux source"/></Attributes>
        <Obs><ObsDimension value="2025-Q1"/><ObsValue value="-0.123456789"/></Obs>
        <Obs><ObsDimension value="2025-Q2"/><ObsValue value="0.25"/></Obs>
        <Obs><ObsDimension value="2025-Q3"/><ObsValue value="NaN"/></Obs>\(extra)</Series></DataSet></GenericData>
        """.utf8)
    }

    @Test func discoversUnlistedDatasetsAndPreservesAgencyAndVersion() throws {
        let xml = Data("""
        <Structure><Dataflow id="NEVER_HARDCODED" agencyID="OTHER" version="3.1"><Name xml:lang="en">English</Name><Name xml:lang="fr">Nouveau catalogue</Name></Dataflow></Structure>
        """.utf8)
        let flows = try SDMXParser.datasets(xml, source: .oecd)
        #expect(flows.count == 1)
        #expect(flows[0].code == "NEVER_HARDCODED")
        #expect(flows[0].agency == "OTHER" && flows[0].version == "3.1")
        #expect(flows[0].title == "Nouveau catalogue")
    }
    @Test func preservesDecimalQuarterDatesAndPercentagePoints() throws {
        let value = try SDMXParser.series(data(), dataset: dataset, structure: structure)
        #expect(value.observations.count == 2)
        #expect(value.observations[0].value == Decimal(string: "-0.123456789"))
        #expect(value.frequency == .quarterly && value.canAlert)
        #expect(value.observations[0].periodEnd == SDMXParser.period("2025-03-31")?.start)
        #expect(value.change(for: .all) == Decimal(string: "0.373456789"))
    }
    @Test func sourceScaleIsNeverMultipliedAgainAndIndexVariationIsUnavailable() throws {
        let volume = try SDMXParser.series(data(unit: "USD", multiplier: "9"), dataset: dataset, structure: structure)
        #expect(volume.latest?.value == Decimal(string: "0.25"))
        #expect(volume.displayUnit.contains("10^9"))
        let index = try SDMXParser.series(data(unit: "IX"), dataset: dataset, structure: structure)
        #expect(index.change(for: .all) == nil)
    }
    @Test func eurostatUsesItsPublishedCompoundUnitWithoutMultiplyingValues() {
        let dataset = StatisticalDataset(source: .eurostat, code: "ANY", agency: "ESTAT", version: "1.0", title: "Encours", detail: "")
        let descriptor = StatisticalSeriesDescriptor(dataset: dataset, key: "A.FR.MIO_EUR", dimensionIDs: [],
            fields: ["UNIT": "MIO_EUR"], labels: ["UNIT": "Millions d’euros"])
        #expect(descriptor.multiplier == 0)
        #expect(descriptor.canAlert)
        #expect(descriptor.displayUnit == "Millions d’euros")
    }
    @Test func rejectsObservationScaleChangesAndUninterpretedDates() {
        let changed = "<Obs><ObsDimension value=\"2025-Q4\"/><ObsValue value=\"1\"/><Attributes><Value id=\"UNIT_MULT\" value=\"6\"/></Attributes></Obs>"
        #expect(throws: (any Error).self) { _ = try SDMXParser.series(data(extra: changed), dataset: dataset, structure: structure) }
        let unknownDate = "<Obs><ObsDimension value=\"2025-UNKNOWN\"/><ObsValue value=\"1\"/></Obs>"
        #expect(throws: (any Error).self) { _ = try SDMXParser.series(data(extra: unknownDate), dataset: dataset, structure: structure) }
    }
    @Test func declinesAlertsWhenSourceScaleIsUnknown() throws {
        let missing = Data(String(decoding: data(), as: UTF8.self).replacingOccurrences(of: "<Value id=\"UNIT_MULT\" value=\"0\"/>", with: "").utf8)
        let value = try SDMXParser.series(missing, dataset: dataset, structure: structure)
        #expect(!value.canAlert)
        #expect(!value.observations.isEmpty)
    }
    @Test func separatesProvidersAndPreservesNewMetadataInCache() throws {
        let value = try SDMXParser.series(data(), dataset: dataset, structure: structure)
        let other = StatisticalDataset(source: .bis, code: dataset.code, agency: dataset.agency, version: dataset.version, title: dataset.title, detail: "")
        let bis = try SDMXParser.series(data(), dataset: other, structure: structure)
        #expect(value.id != bis.id)
        let decoded = try JSONDecoder().decode(MarketSeries.self, from: JSONEncoder().encode(value))
        #expect(decoded == value)
        #expect(decoded.replacing(observations: value.observations).statisticalDescriptor == value.statisticalDescriptor)
        #expect(decoded.withID(decoded.id).statisticalDescriptor == value.statisticalDescriptor)
    }
    @Test func requestsStayOnPublicHostsWithoutCredentials() throws {
        for source in StatisticalSource.allCases {
            let request = StatisticalClient.catalogueRequest(source)
            #expect(request.url?.scheme == "https")
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        }
        for key in ["../private", "D..FR", "all", "D.FR&api_key=secret", "D.FR\n"] {
            #expect(throws: (any Error).self) { _ = try StatisticalClient.observationsRequest(dataset: dataset, key: key) }
        }
    }
    @Test func discoversFedMeasuresInsteadOfConflatingTargetRateAndEffectiveRate() throws {
        let json = Data("""
        {"refRates":[{"type":"EFFR","effectiveDate":"2025-01-02","percentRate":4.33,"targetRateFrom":4.25,"targetRateTo":4.50,"volumeInBillions":100}]}
        """.utf8)
        let flows = try StatisticalClient.fedDatasets(json)
        let flow = try #require(flows.first)
        #expect(flow.metadata["MEASURE:targetRateFrom"] != nil)
        let target = try StatisticalClient.parse(json, dataset: flow, structure: structure, key: "targetRateFrom")
        let effective = try StatisticalClient.parse(json, dataset: flow, structure: structure, key: "percentRate")
        #expect(target.id != effective.id)
        #expect(target.latest?.value == Decimal(string: "4.25"))
        #expect(effective.latest?.value == Decimal(string: "4.33"))
    }
    @Test func rejectsEntityDeclarations() {
        let xml = Data("<!DOCTYPE x [<!ENTITY test 'expanded'>]><Structure><Dataflow id='x' agencyID='x'><Name>&test;</Name></Dataflow></Structure>".utf8)
        #expect(throws: (any Error).self) { _ = try SDMXParser.datasets(xml, source: .insee) }
    }
}
