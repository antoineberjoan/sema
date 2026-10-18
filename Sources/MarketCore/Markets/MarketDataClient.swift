// Charge le catalogue et les clôtures avec une authentification limitée à l’hôte officiel.
import Foundation

public actor MarketDataClient {
    private static let numberLocale = Locale(identifier: "en_US_POSIX")
    private static let twelveMinuteLimit = 8
    private static let minute: TimeInterval = 60
    private static let twelveHistorySize = 5000
    private static let priceDigits = 2
    private static let smallPriceDigits = 6
    private let provider: MarketProvider
    private let session: URLSession
    private static let alphaSpacing: TimeInterval = 1.1
    private var nextAlphaRequest = Date.distantPast
    private var catalogueCache: MarketCatalogue?
    private var catalogueGeneration = UUID()
    private var requests: [Date] = []

    public init(provider: MarketProvider, session: URLSession? = nil) {
        self.provider = provider
        // Aucune URL authentifiée ne doit être écrite dans le cache HTTP.
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil; configuration.httpCookieStorage = nil
        self.session = session ?? URLSession(configuration: configuration, delegate: RedirectBlocker(), delegateQueue: nil)
    }

    public func validate(key: String) async throws {
        let data = try await request(provider == .twelveData ? "api_usage" : "query",
            parameters: provider == .twelveData ? [:] : ["function": "GLOBAL_QUOTE", "symbol": "IBM"], key: key)
        if provider == .twelveData {
            guard data["plan_limit"] != nil else { throw MarketDataError.invalidData }
        } else {
            guard let quote = data["Global Quote"] as? [String: String], !quote.isEmpty else { throw MarketDataError.invalidKey }
        }
    }

    public func invalidateCatalogue() {
        catalogueGeneration = UUID(); catalogueCache = nil
    }

    public func catalogue(key: String) async throws -> MarketCatalogue {
        if let catalogueCache { return catalogueCache }
        let generation = catalogueGeneration
        let value: MarketCatalogue
        if provider == .twelveData {
            let usage = try await request("api_usage", parameters: [:], key: key)
            guard let plan = usage["plan_category"] as? String, MarketCatalogue.recognizes(plan) else {
                throw MarketDataError.unknownPlan
            }
            var instruments: [MarketInstrument] = []
            // Sans outputsize, le fournisseur documente le retour du catalogue complet.
            for (endpoint, kind) in [("stocks", nil as String?), ("etf", "ETF"), ("indices", "Index")] {
                let data = try await request(endpoint, parameters: ["show_plan": "true", "include_delisted": "false"], key: key)
                instruments += try MarketCatalogue.twelve(data, plan: plan, kind: kind)
                try Task.checkCancellation()
            }
            var seen: Set<String> = []
            value = MarketCatalogue(instruments: instruments.filter { seen.insert($0.id).inserted }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
                scope: "Actions, ETF et indices · forfait \(plan.capitalized)")
        } else {
            let body = try await requestBody("query", parameters: ["function": "LISTING_STATUS", "state": "active"], key: key)
            if let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] { try Self.checkError(data) }
            let instruments = try MarketCatalogue.alpha(body)
            value = MarketCatalogue(instruments: instruments.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
                scope: "Actions et ETF américains · catalogue Alpha Vantage")
        }
        try Task.checkCancellation()
        guard generation == catalogueGeneration else { throw CancellationError() }
        catalogueCache = value
        return value
    }

    public func fetch(_ instrument: MarketInstrument, key: String) async throws -> MarketSeries {
        guard instrument.provider == provider else { throw MarketDataError.invalidData }
        let parameters: [String: String]
        if provider == .twelveData {
            var query = ["symbol": instrument.symbol, "interval": instrument.weekly ? "1week" : "1day",
                         "outputsize": String(Self.twelveHistorySize), "order": "asc", "adjust": "none"]
            if !instrument.exchange.isEmpty { query["exchange"] = instrument.exchange }
            parameters = query
        } else {
            parameters = ["function": instrument.weekly ? "TIME_SERIES_WEEKLY" : "TIME_SERIES_DAILY", "symbol": instrument.symbol]
        }
        let data = try await request(provider == .twelveData ? "time_series" : "query", parameters: parameters, key: key)
        return try Self.decodeSeries(data, instrument: instrument, now: .now)
    }

    static func decodeSeries(_ data: [String: Any], instrument: MarketInstrument, now: Date) throws -> MarketSeries {
        let rows: [(String, String)]
        if instrument.provider == .twelveData {
            guard let values = data["values"] as? [[String: String]],
                  let meta = data["meta"] as? [String: Any],
                  meta["symbol"] as? String == instrument.symbol,
                  meta["interval"] as? String == (instrument.weekly ? "1week" : "1day") else { throw MarketDataError.invalidData }
            if let currency = meta["currency"] as? String, currency != instrument.currency { throw MarketDataError.invalidData }
            if !instrument.exchange.isEmpty, let exchange = meta["exchange"] as? String,
               exchange != instrument.exchange { throw MarketDataError.invalidData }
            rows = try values.map { row in
                guard let date = row["datetime"], let close = row["close"] else { throw MarketDataError.invalidData }
                return (date, close)
            }
        } else {
            let field = instrument.weekly ? "Weekly Time Series" : "Time Series (Daily)"
            guard let values = data[field] as? [String: [String: String]],
                  let meta = data["Meta Data"] as? [String: String],
                  meta["2. Symbol"] == instrument.symbol else { throw MarketDataError.invalidData }
            rows = try values.map { date, row in
                guard let close = row["4. close"] else { throw MarketDataError.invalidData }
                return (date, close)
            }
        }
        let formatter = DateFormatter()
        formatter.locale = Self.numberLocale; formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"; formatter.isLenient = false
        var precision = 0
        let points = try rows.map { date, close -> MarketObservation in
            guard date.count == 10, let day = formatter.date(from: date), formatter.string(from: day) == date,
                  close.range(of: #"^[0-9]+(?:\.[0-9]+)?$"#, options: .regularExpression) != nil,
                  let value = Decimal(string: close, locale: Self.numberLocale), !value.isNaN,
                  value >= 0 else { throw MarketDataError.invalidData }
            precision = max(precision, close.split(separator: ".").dropFirst().first?.count ?? 0)
            return MarketObservation(date: day, value: value)
        }
        guard !points.isEmpty, !instrument.displayUnit.isEmpty else { throw MarketDataError.unavailable }
        let latest = points.max { $0.date < $1.date }!.value
        let detailed = instrument.kind.lowercased().contains("currency") || instrument.kind.lowercased().contains("crypto") || (latest > 0 && latest < 1)
        let displayDigits = min(precision, detailed ? Self.smallPriceDigits : Self.priceDigits)
        return MarketSeries(id: instrument.id, name: instrument.name,
            subtitle: instrument.summary + " · cours non ajustés",
            category: .markets, unit: .number, fractionDigits: displayDigits, source: instrument.provider.title,
            sourceURL: instrument.provider.website, isDemo: false, frequency: instrument.weekly ? .weekly : .businessDaily,
            observations: points, syncedAt: now, hasCompleteHistory: false, marketInstrument: instrument)
    }

    private final class RedirectBlocker: NSObject, URLSessionTaskDelegate, Sendable {
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                        completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
            completionHandler(nil)
        }
    }

    private func request(_ endpoint: String, parameters: [String: String], key: String) async throws -> [String: Any] {
        let body = try await requestBody(endpoint, parameters: parameters, key: key)
        guard let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { throw MarketDataError.invalidData }
        try Self.checkError(data)
        return data
    }

    private func requestBody(_ endpoint: String, parameters: [String: String], key: String) async throws -> Data {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw MarketDataError.missingKey }
        if provider == .alphaVantage {
            let reserved = max(Date.now, nextAlphaRequest)
            nextAlphaRequest = reserved.addingTimeInterval(Self.alphaSpacing)
            let delay = reserved.timeIntervalSinceNow
            if delay > 0 { try await Task.sleep(for: .seconds(delay)) }
            try Task.checkCancellation()
        }
        if provider == .twelveData {
            requests.removeAll { Date.now.timeIntervalSince($0) >= Self.minute }
            if requests.count >= Self.twelveMinuteLimit, let first = requests.first {
                try await Task.sleep(for: .seconds(max(0, Self.minute - Date.now.timeIntervalSince(first))))
                return try await requestBody(endpoint, parameters: parameters, key: key)
            }
            requests.append(.now)
        }
        var query = parameters
        // Exception demandée par Antoine le 17 octobre : Alpha Vantage ne documente que ce mode.
        if provider == .alphaVantage { query["apikey"] = key }
        var components = URLComponents(string: provider == .twelveData ? "https://api.twelvedata.com" : "https://www.alphavantage.co")!
        components.path = "/" + endpoint
        components.queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.timeoutInterval = 30
        if provider == .twelveData { request.setValue("apikey \(key)", forHTTPHeaderField: "Authorization") }
        do {
            let (body, response) = try await session.data(for: request)
            try Task.checkCancellation()
            guard let response = response as? HTTPURLResponse else { throw MarketDataError.invalidData }
            if response.statusCode == 401 { throw MarketDataError.invalidKey }
            if response.statusCode == 403 { throw MarketDataError.entitlement }
            if response.statusCode == 429 { throw MarketDataError.quota }
            guard (200..<300).contains(response.statusCode) else {
                if let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] { try Self.checkError(data) }
                throw MarketDataError.network
            }
            return body
        } catch is CancellationError { throw CancellationError() }
        catch let error as MarketDataError { throw error }
        catch { throw MarketDataError.network }
    }

    static func checkError(_ data: [String: Any]) throws {
        let message = [data["message"], data["Information"], data["Note"], data["Error Message"]]
            .compactMap { $0 as? String }.joined(separator: " ").lowercased()
        let code = data["code"] as? Int
        if code == 401 || message.contains("invalid api key") || message.contains("apikey is invalid") { throw MarketDataError.invalidKey }
        if code == 429 || message.contains("rate limit") || message.contains("call frequency") || message.contains("requests per day") { throw MarketDataError.quota }
        if code == 403 || message.contains("premium") || message.contains("upgrade") || message.contains("subscription") || message.contains("not yet entitled") { throw MarketDataError.entitlement }
        if data["status"] as? String == "error" || !message.isEmpty { throw MarketDataError.unavailable }
    }
}
