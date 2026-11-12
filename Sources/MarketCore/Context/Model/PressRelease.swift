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
}
