// Lit les flux RSS ou Atom des banques centrales et en garde les communiqués datés et liés.
import Foundation

public struct PressReleaseClient: Sendable {
    static let timeout: TimeInterval = 20
    /// Dates RSS, par exemple « Thu, 05 Nov 2026 14:00:00 -0500 » ou « … GMT ».
    private static let rssFormats = ["EEE, dd MMM yyyy HH:mm:ss Z", "EEE, dd MMM yyyy HH:mm:ss zzz", "EEE, d MMM yyyy HH:mm:ss Z"]
    public init() {}

    public func releases(_ feed: CentralBankFeed) async throws -> [PressRelease] {
        var request = URLRequest(url: feed.url)
        request.timeoutInterval = Self.timeout
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw PublicDataError.unavailable }
        return try Self.parse(data, feed: feed)
    }

    /// Les `item` RSS et les `entry` Atom sont tous deux lus ; une entrée sans titre, lien ou date est omise.
    public static func parse(_ data: Data, feed: CentralBankFeed) throws -> [PressRelease] {
        let root = try XMLTree.read(data)
        let items = root.descendants("item") + root.descendants("entry")
        return items.compactMap { item -> PressRelease? in
            let title = item.child("title")?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let address = item.child("link").map { $0.attributes["href"] ?? $0.text }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let dateText = (item.child("pubDate") ?? item.child("published") ?? item.child("updated"))?.text
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty, let link = URL(string: address), link.scheme == "https", let date = Self.date(dateText) else { return nil }
            return PressRelease(feed: feed, title: title, link: link, publishedAt: date)
        }.sorted { $0.publishedAt > $1.publishedAt }
    }

    static func date(_ text: String) -> Date? {
        if let date = ISO8601DateFormatter().date(from: text) { return date }
        let formatter = DateFormatter()
        formatter.locale = .posix
        for format in rssFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: text) { return date }
        }
        return nil
    }
}
