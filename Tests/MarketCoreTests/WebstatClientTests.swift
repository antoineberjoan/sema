import Foundation
import Testing
@testable import MarketCore

struct WebstatClientTests {
    private let now = Date(timeIntervalSince1970: 1_792_022_400) // 2026-10-15 UTC

    /// One independent sample for each product indicator, including a month not yet finished.
    private func fixture(extraRows: String = "") -> Data {
        let keys = [
            "FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD", "FM.D.U2.EUR.4F.KR.DFR.LEV",
            "EXR.D.USD.EUR.SP00.A", "EXR.D.JPY.EUR.SP00.A", "EXR.D.CHF.EUR.SP00.A",
            "MIR1.M.FR.B.L23FRLA.D.R.A.2230U6.EUR.O", "MIR1.M.FR.B.L23FRLP.H.R.A.2250U6.EUR.O",
            "HICP.M.FR.N.000000.4D0.ANR", "MIR1.M.FR.B.L23FRLD.D.R.A.2254U6.EUR.O",
            "ESTR.B.EU000A2X2A25.WT", "HICP.M.U2.N.000000.4D0.ANR",
            "EXR.D.GBP.EUR.SP00.A", "MIR1.M.FR.B.A22HR.A.R.A.2254U6.EUR.N"
        ]
        let rows = keys.map { key in
            """
            {"series_key":"\(key)","time_period_start":"2026-09-01","time_period_end":"2026-09-30","obs_value":1.1195000001,"obs_status":"A","updated_at":"2026-10-01T08:00:00+00:00"}
            """
        }.joined(separator: ",")
        return Data(("[" + rows + (extraRows.isEmpty ? "" : "," + extraRows) + "]").utf8)
    }

    @Test
    func decodesExactDecimalsUnitsFrequencyAndSource() throws {
        let series = try WebstatClient.parse(fixture(), now: now)
        #expect(series.count == 13)
        #expect(Set(series.map(\.id)).count == 13)
        #expect(series.allSatisfy { !$0.isDemo && $0.sourceURL?.host == "webstat.banque-france.fr" })
        let dollar = try #require(series.first { $0.id == "eurusd" })
        #expect(dollar.unit == .usd)
        #expect(dollar.latest?.value == Decimal(string: "1.1195000001"))
        #expect(series.first { $0.id == "eurgbp" }?.unit == .gbp)
        #expect(series.first { $0.id == "inflation" }?.frequency == .monthly)
        #expect(series.first { $0.id == "estr" }?.frequency == .daily)
    }

    @Test
    func excludesMissingAndFutureValuesButKeepsNegativeInterestRates() throws {
        let rows = """
        {"series_key":"EXR.D.USD.EUR.SP00.A","time_period_start":"2026-10-02","time_period_end":"2026-10-02","obs_value":null,"obs_status":"M"},
        {"series_key":"EXR.D.USD.EUR.SP00.A","time_period_start":"2026-10-03","time_period_end":"2026-10-03","obs_value":-1,"obs_status":"A"},
        {"series_key":"EXR.D.USD.EUR.SP00.A","time_period_start":"2099-01-01","time_period_end":"2099-01-01","obs_value":10,"obs_status":"A"},
        {"series_key":"ESTR.B.EU000A2X2A25.WT","time_period_start":"2026-10-14","time_period_end":"2026-10-14","obs_value":-0.55,"obs_status":"A"}
        """
        let series = try WebstatClient.parse(fixture(extraRows: rows), now: now)
        #expect(series.first { $0.id == "eurusd" }?.observations.count == 1)
        #expect(series.first { $0.id == "estr" }?.latest?.value == Decimal(string: "-0.55"))
    }

    @Test
    func preservesCurrentMonthlyPeriodAndLatestRevision() throws {
        let rows = """
        {"series_key":"MIR1.M.FR.B.L23FRLA.D.R.A.2230U6.EUR.O","time_period_start":"2026-10-01","time_period_end":"2026-10-31","obs_value":1.7,"obs_status":"A","updated_at":"2026-10-02T08:00:00.125+00:00"},
        {"series_key":"MIR1.M.FR.B.L23FRLA.D.R.A.2230U6.EUR.O","time_period_start":"2026-10-01","time_period_end":"2026-10-31","obs_value":1.5,"obs_status":"E","updated_at":"2026-10-01T08:00:00+00:00"}
        """
        let series = try WebstatClient.parse(fixture(extraRows: rows), now: now)
        let livret = try #require(series.first { $0.id == "livreta" })
        #expect(livret.latest?.value == Decimal(string: "1.7"))
        #expect((livret.latest?.periodEnd ?? .distantPast) > now)
        #expect(livret.latest?.updatedAt != nil)
        #expect(livret.latest?.status == "A")
        // September has 30 days; the same calendar-month logic also handles a 31-day gap.
        #expect(livret.history(for: .month).count == 2)
    }

    @Test
    func usesCalendarMonthsForMonthlySeries() throws {
        let dates = ISO8601DateFormatter()
        dates.formatOptions = [.withFullDate]
        let series = MarketSeries(id: "rate", name: "Rate", subtitle: "", category: .savings,
            unit: .percent, source: "Fixture", isDemo: false, frequency: .monthly,
            observations: [MarketObservation(date: dates.date(from: "2026-07-01")!, value: 2),
                           MarketObservation(date: dates.date(from: "2026-08-01")!, value: 1)])
        #expect(series.history(for: .month).count == 2)
        #expect(series.change(for: .month) == -1)
        #expect(!series.hasAnnualHistory)
    }

    @Test
    func incompleteOrInvalidExportDoesNotBecomeAConnectedSource() {
        for body in ["[]", "{}", "broken", "[{\"series_key\":\"x\"}]"] {
            #expect(throws: (any Error).self) { _ = try WebstatClient.parse(Data(body.utf8), now: now) }
        }
    }

    @Test
    func handlesKeyQuotaAndServerErrorsWithoutEchoingServerBody() {
        for status in [401, 403, 404, 429, 500] {
            do {
                _ = try WebstatClient.parse(Data("private-key-echo".utf8), statusCode: status, now: now)
                Issue.record("An HTTP error was accepted")
            } catch {
                #expect(!error.localizedDescription.contains("private-key-echo"))
                if status == 429 { #expect(error.localizedDescription.contains("quota")) }
            }
        }
    }

    @Test
    func requestKeepsCredentialOutOfURLAndUsesBoundedGroupedExport() throws {
        let request = try WebstatClient.request(apiKey: " fixture-secret ", now: now)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Apikey fixture-secret")
        let url = try #require(request.url)
        #expect(url.host == "webstat.banque-france.fr")
        #expect(!url.absoluteString.contains("fixture-secret"))
        #expect(!url.absoluteString.contains("apikey="))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        let filter = try #require(items?.first { $0.name == "where" }?.value)
        #expect(filter.contains("2021-10-15"))
        #expect(filter.contains("HICP.M.FR.N.000000.4D0.ANR"))
        #expect(!filter.contains("FRMOYTEC10"))
        #expect(throws: (any Error).self) { _ = try WebstatClient.request(apiKey: "   ") }
        #expect(throws: (any Error).self) { _ = try WebstatClient.request(apiKey: "bad\r\nkey") }
    }

    @Test
    func existingCacheRemainsDecodableAndNewMetadataSurvivesRoundTrip() throws {
        let old = """
        {"id":"eurusd","name":"Dollar","subtitle":"","category":"markets","unit":"usd","fractionDigits":4,"source":"BCE","isDemo":false,"observations":[{"date":0,"value":1.12}]}
        """
        let previous = try JSONDecoder().decode(MarketSeries.self, from: Data(old.utf8))
        #expect(previous.frequency == nil)
        #expect(previous.latest?.updatedAt == nil)
        let current = try WebstatClient.parse(fixture(), now: now)
        #expect(try JSONDecoder().decode([MarketSeries].self, from: JSONEncoder().encode(current)) == current)
    }
}
