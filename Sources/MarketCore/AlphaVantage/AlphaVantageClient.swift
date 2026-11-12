// Parle à Alpha Vantage : un seul point d'accès, une clé en paramètre d'adresse, un appel toutes les 1,1 seconde.
import Foundation

public actor AlphaVantageClient: MarketDataConnector {
    private static let host = "https://www.alphavantage.co"
    private static let spacing: TimeInterval = 1.1
    static let newsLimit = 10
    private let session: URLSession
    private var nextRequest = Date.distantPast
    private var catalogueCache: MarketCatalogue?
    private var catalogueGeneration = UUID()

    public init(session: URLSession? = nil) {
        self.session = session ?? MarketDataTransport.makeSession()
    }

    public func validate(key: String) async throws {
        let data = try await request(["function": "GLOBAL_QUOTE", "symbol": "IBM"], key: key)
        guard let quote = data["Global Quote"] as? [String: String], !quote.isEmpty else { throw MarketDataError.invalidKey }
    }

    public func invalidateCatalogue() {
        catalogueGeneration = UUID(); catalogueCache = nil
    }

    public func catalogue(key: String) async throws -> MarketCatalogue {
        if let catalogueCache { return catalogueCache }
        let generation = catalogueGeneration
        let body = try await requestBody(["function": "LISTING_STATUS", "state": "active"], key: key)
        if let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] { try MarketDataFormat.checkError(data) }
        let instruments = try AlphaVantageMapping.instruments(body)
        let value = MarketCatalogue(instruments: instruments.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
            scope: "Actions et ETF américains · catalogue Alpha Vantage")
        try Task.checkCancellation()
        guard generation == catalogueGeneration else { throw CancellationError() }
        catalogueCache = value
        return value
    }

    public func fetch(_ instrument: MarketInstrument, key: String) async throws -> MarketSeries {
        guard instrument.provider == .alphaVantage else { throw MarketDataError.invalidData }
        let data = try await request(["function": instrument.weekly ? "TIME_SERIES_WEEKLY" : "TIME_SERIES_DAILY", "symbol": instrument.symbol], key: key)
        return try AlphaVantageMapping.series(data, instrument: instrument, now: .now)
    }

    /// Market news of a day, with the key already kept for prices; one call of the daily quota.
    public func news(from start: Date, to end: Date, key: String) async throws -> [Headline] {
        let body = try await requestBody([
            "function": "NEWS_SENTIMENT", "topics": "financial_markets", "sort": "RELEVANCE", "limit": String(Self.newsLimit),
            "time_from": Self.newsStamp(start), "time_to": Self.newsStamp(end)], key: key)
        if let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] { try MarketDataFormat.checkError(data.filter { $0.key != "feed" }) }
        return try AlphaVantageMapping.news(body)
    }

    private static func newsStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .posix
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmm"
        return formatter.string(from: date)
    }

    private func request(_ parameters: [String: String], key: String) async throws -> [String: Any] {
        try MarketDataTransport.object(try await requestBody(parameters, key: key))
    }

    private func requestBody(_ parameters: [String: String], key: String) async throws -> Data {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw MarketDataError.missingKey }
        let reserved = max(Date.now, nextRequest)
        nextRequest = reserved.addingTimeInterval(Self.spacing)
        let delay = reserved.timeIntervalSinceNow
        if delay > 0 { try await Task.sleep(for: .seconds(delay)) }
        try Task.checkCancellation()
        var query = parameters
        // Exception demandée par Antoine le 17 octobre : Alpha Vantage ne documente que ce mode.
        query["apikey"] = key
        return try await MarketDataTransport.send(MarketDataTransport.request(host: Self.host, endpoint: "query", query: query), on: session)
    }
}
