// Cherche dans GDELT les titres anglophones d’une séance sur les marchés, sans clé ni compte.
import Foundation

public struct GDELTClient: Sendable {
    static let baseURL = "https://api.gdeltproject.org/api/v2/doc/doc"
    static let timeout: TimeInterval = 20
    static let maximumRecords = 10
    /// Broad market vocabulary; the day window and the title list stay facts, never causes.
    static let marketQuery = #"("stock market" OR "wall street" OR stocks OR "central bank" OR "treasury yields") sourcelang:english"#
    public init() {}

    public static func request(from start: Date, to end: Date) -> URLRequest {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "query", value: marketQuery), URLQueryItem(name: "mode", value: "artlist"),
            URLQueryItem(name: "format", value: "json"), URLQueryItem(name: "sort", value: "hybridrel"),
            URLQueryItem(name: "maxrecords", value: String(maximumRecords)),
            URLQueryItem(name: "startdatetime", value: stamp(start)), URLQueryItem(name: "enddatetime", value: stamp(end)),
        ]
        var request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.timeoutInterval = timeout
        return request
    }

    public func headlines(from start: Date, to end: Date) async throws -> [Headline] {
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: Self.request(from: start, to: end))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw StatisticalClient.ClientError.unavailable }
        return try Self.parse(data)
    }

    public static func parse(_ data: Data) throws -> [Headline] {
        guard let root = try? JSONDecoder().decode([String: WebstatValue].self, from: data) else { throw StatisticalClient.ClientError.invalidData }
        guard case .array(let articles) = root["articles"] else { return [] }
        return articles.compactMap { value -> Headline? in
            guard case .object(let article) = value, let title = article["title"]?.text, !title.isEmpty,
                  let link = article["url"]?.text.flatMap(URL.init(string:)), link.scheme == "https",
                  let date = article["seendate"]?.text.flatMap(Headline.compactDate) else { return nil }
            return Headline(title: title, link: link, publisher: article["domain"]?.text ?? link.host ?? "", publishedAt: date)
        }
    }

    private static func stamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .posix
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter.string(from: date)
    }
}
