// Titre d’actualité retrouvé pour une séance : texte, lien, éditeur et heure de publication.
import Foundation

public struct Headline: Codable, Equatable, Identifiable, Sendable {
    public let title: String
    public let link: URL
    public let publisher: String
    public let publishedAt: Date
    public var id: String { link.absoluteString }

    public init(title: String, link: URL, publisher: String, publishedAt: Date) {
        self.title = title; self.link = link; self.publisher = publisher; self.publishedAt = publishedAt
    }

    /// Compact UTC stamps used by GDELT and Alpha Vantage, for example « 20261105T221500Z » or « 20261105T221500 ».
    static func compactDate(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = .posix
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = text.hasSuffix("Z") ? "yyyyMMdd'T'HHmmss'Z'" : "yyyyMMdd'T'HHmmss"
        return formatter.date(from: text)
    }
}
