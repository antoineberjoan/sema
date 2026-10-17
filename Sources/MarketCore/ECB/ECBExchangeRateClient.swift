// Télécharge et décode les taux de référence BCE publiés, sans les présenter comme des cours en direct.
import Foundation

/// Public ECB reference rates. These are daily publications, not live trading quotes.
public struct ECBExchangeRateClient: Sendable {
    static let timeout: TimeInterval = 20
    public enum ClientError: Error, LocalizedError {
        case invalidResponse, invalidXML, noObservations
        public var errorDescription: String? {
            switch self {
            case .invalidResponse: "La BCE a renvoyé une réponse inattendue."
            case .invalidXML: "Le format des données BCE n’a pas pu être lu."
            case .noObservations: "Aucune observation de change exploitable."
            }
        }
    }

    public static let endpoint = URL(string: "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist-90d.xml")!

    public init() {}

    public func fetch() async throws -> [MarketSeries] {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = Self.timeout
        let session = URLSession(configuration: configuration)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(from: Self.endpoint)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw ClientError.invalidResponse
        }
        return try Self.parse(data)
    }

    public static func parse(_ data: Data) throws -> [MarketSeries] {
        let delegate = RatesXMLDelegate()
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate
        guard parser.parse() else { throw ClientError.invalidXML }
        let currencies: [(code: String, id: String, name: String, unit: ValueUnit, digits: Int)] = [
            ("USD", "eurusd", "Euro / Dollar", .usd, 4),
            ("JPY", "eurjpy", "Euro / Yen", .jpy, 2),
            ("CHF", "eurchf", "Euro / Franc suisse", .chf, 4)
        ]
        let series = currencies.compactMap { currency -> MarketSeries? in
            guard let observations = delegate.observations[currency.code], !observations.isEmpty else { return nil }
            return MarketSeries(
                id: currency.id, name: currency.name, subtitle: "\(currency.code) pour 1 EUR",
                category: .markets, unit: currency.unit, fractionDigits: currency.digits,
                source: "Banque centrale européenne", sourceURL: Self.endpoint,
                isDemo: false, observations: observations
            )
        }
        guard !series.isEmpty else { throw ClientError.noObservations }
        return series
    }
}

private final class RatesXMLDelegate: NSObject, XMLParserDelegate {
    var observations: [String: [MarketObservation]] = [:]
    private var currentDate: Date?
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }()

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
        guard elementName == "Cube" else { return }
        if let date = attributeDict["time"] {
            currentDate = dateFormatter.date(from: date)
        }
        guard let date = currentDate,
              let currency = attributeDict["currency"],
              let rawRate = attributeDict["rate"],
              rawRate.range(of: "^[0-9]+(?:\\.[0-9]+)?$", options: .regularExpression) != nil,
              let rate = Decimal(string: rawRate, locale: Locale(identifier: "en_US_POSIX")), rate > 0 else { return }
        observations[currency, default: []].append(MarketObservation(date: date, value: rate))
    }
}
