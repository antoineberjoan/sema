// Parle à Twelve Data : la clé part dans l'en-tête d'autorisation, vers l'hôte officiel seulement.
import Foundation

public actor TwelveDataClient: MarketDataConnector {
    private static let host = "https://api.twelvedata.com"
    private static let minuteLimit = 8
    private static let minute: TimeInterval = 60
    private static let historySize = 5000
    private let session: URLSession
    private var catalogueCache: MarketCatalogue?
    private var catalogueGeneration = UUID()
    private var requests: [Date] = []

    public init(session: URLSession? = nil) {
        self.session = session ?? MarketDataTransport.makeSession()
    }

    public func validate(key: String) async throws {
        let data = try await request("api_usage", parameters: [:], key: key)
        guard data["plan_limit"] != nil else { throw MarketDataError.invalidData }
    }

    public func invalidateCatalogue() {
        catalogueGeneration = UUID(); catalogueCache = nil
    }

    public func catalogue(key: String) async throws -> MarketCatalogue {
        if let catalogueCache { return catalogueCache }
        let generation = catalogueGeneration
        let usage = try await request("api_usage", parameters: [:], key: key)
        guard let plan = usage["plan_category"] as? String, TwelveDataMapping.recognizes(plan) else {
            throw MarketDataError.unknownPlan
        }
        var instruments: [MarketInstrument] = []
        // Sans outputsize, le fournisseur documente le retour du catalogue complet.
        for (endpoint, kind) in [("stocks", nil as String?), ("etf", "ETF"), ("indices", "Index")] {
            let data = try await request(endpoint, parameters: ["show_plan": "true", "include_delisted": "false"], key: key)
            instruments += try TwelveDataMapping.instruments(data, plan: plan, kind: kind)
            try Task.checkCancellation()
        }
        var seen: Set<String> = []
        let value = MarketCatalogue(instruments: instruments.filter { seen.insert($0.id).inserted }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
            scope: "Actions, ETF et indices · forfait \(plan.capitalized)")
        try Task.checkCancellation()
        guard generation == catalogueGeneration else { throw CancellationError() }
        catalogueCache = value
        return value
    }

    public func fetch(_ instrument: MarketInstrument, key: String) async throws -> MarketSeries {
        guard instrument.provider == .twelveData else { throw MarketDataError.invalidData }
        var query = ["symbol": instrument.symbol, "interval": instrument.isWeekly ? "1week" : "1day",
                     "outputsize": String(Self.historySize), "order": "asc", "adjust": "none"]
        if !instrument.exchange.isEmpty { query["exchange"] = instrument.exchange }
        let data = try await request("time_series", parameters: query, key: key)
        return try TwelveDataMapping.series(data, instrument: instrument, now: .now)
    }

    private func request(_ endpoint: String, parameters: [String: String], key: String) async throws -> [String: Any] {
        try MarketDataTransport.object(try await requestBody(endpoint, parameters: parameters, key: key))
    }

    private func requestBody(_ endpoint: String, parameters: [String: String], key: String) async throws -> Data {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw MarketDataError.missingKey }
        requests.removeAll { Date.now.timeIntervalSince($0) >= Self.minute }
        if requests.count >= Self.minuteLimit, let first = requests.first {
            try await Task.sleep(for: .seconds(max(0, Self.minute - Date.now.timeIntervalSince(first))))
            return try await requestBody(endpoint, parameters: parameters, key: key)
        }
        requests.append(.now)
        var request = MarketDataTransport.request(host: Self.host, endpoint: endpoint, query: parameters)
        request.setValue("apikey \(key)", forHTTPHeaderField: "Authorization")
        return try await MarketDataTransport.send(request, on: session)
    }
}
