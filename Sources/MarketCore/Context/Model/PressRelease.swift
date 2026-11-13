// Communiqué publié par une banque centrale : titre, lien officiel et date de publication.
import Foundation

public struct PressRelease: Codable, Equatable, Identifiable, Sendable {
    public let feed: CentralBankFeed
    public let title: String
    public let link: URL
    public let publishedAt: Date
    public var id: String { link.absoluteString }

    public init(feed: CentralBankFeed, title: String, link: URL, publishedAt: Date) {
        self.feed = feed; self.title = title; self.link = link; self.publishedAt = publishedAt
    }

    /// Communiqués publiés entre `start` et `end`, du plus récent au plus ancien.
    public static func recent(_ releases: [PressRelease], from start: Date, to end: Date) -> [PressRelease] {
        releases.filter { (start...end).contains($0.publishedAt) }.sorted { $0.publishedAt > $1.publishedAt }
    }
}
