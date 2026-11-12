// Façon unique d'envoyer une requête aux sources statistiques publiques et d'en lire le code HTTP.
import Foundation

enum PublicDataTransport {
    static let timeout: TimeInterval = 45
    static let maximumKeyLength = 1000
    static let fullHistoryStart = "2000-01-01"

    static func request(_ url: String, accept: String) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.timeoutInterval = timeout
        request.setValue(accept, forHTTPHeaderField: "Accept")
        return request
    }

    /// Envoie la requête sans cache ni cookie. L'appelant lit ensuite le code avec `validate`.
    static func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let result = try await session.data(for: request)
        try Task.checkCancellation()
        return result
    }

    static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw PublicDataError.unavailable }
        if http.statusCode == 429 { throw PublicDataError.quotaReached }
        if http.statusCode == 204 || http.statusCode == 404 { throw PublicDataError.noData }
        guard http.statusCode == 200 else { throw PublicDataError.unavailable }
    }

    /// Refuse toute clé qui pourrait sortir de son segment d'adresse.
    static func validateKey(_ key: String) throws {
        guard !key.isEmpty, key != "all", key.count <= maximumKeyLength,
              key.split(separator: ".", omittingEmptySubsequences: false).allSatisfy({ !$0.isEmpty }),
              key.range(of: "^[A-Za-z0-9_@.:-]+$", options: .regularExpression) != nil else { throw PublicDataError.invalidKey }
    }

    /// Début de la période courante d'historique, en calendrier grégorien UTC.
    static func historyStart(endingAt now: Date) -> (start: Date, calendar: Calendar) {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return (HistoryPeriod.tranche(endingAt: now, calendar: calendar).start, calendar)
    }

    static func component(_ text: String) -> String {
        text.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_@.-"))!
    }

    static func day(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }
}
