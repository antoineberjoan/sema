// Vérifie la lecture des flux RSS et Atom des banques centrales et le refus des entrées incomplètes.
import Foundation
import Testing
@testable import MarketCore

struct PressReleaseClientTests {
    @Test func rssItemsAreReadNewestFirst() throws {
        let rss = Data("""
        <?xml version="1.0"?><rss version="2.0"><channel><title>Fed</title>
        <item><title>Federal Reserve issues FOMC statement</title><link>https://www.federalreserve.gov/a.htm</link><pubDate>Wed, 28 Oct 2026 14:00:00 -0400</pubDate></item>
        <item><title><![CDATA[Minutes & projections]]></title><link>https://www.federalreserve.gov/b.htm</link><pubDate>Thu, 05 Nov 2026 14:00:00 GMT</pubDate></item>
        <item><title>Sans lien</title><pubDate>Thu, 05 Nov 2026 14:00:00 GMT</pubDate></item>
        </channel></rss>
        """.utf8)
        let releases = try PressReleaseClient.parse(rss, feed: .fed)
        #expect(releases.map(\.title) == ["Minutes & projections", "Federal Reserve issues FOMC statement"])
        #expect(releases.first?.publishedAt == ISO8601DateFormatter().date(from: "2026-11-05T14:00:00Z"))
    }

    @Test func atomEntriesUseTheirLinkAttribute() throws {
        let atom = Data("""
        <?xml version="1.0"?><feed xmlns="http://www.w3.org/2005/Atom">
        <entry><title>Monetary policy decisions</title><link href="https://www.ecb.europa.eu/press/pr/a.html"/><updated>2026-10-30T13:15:00Z</updated></entry>
        <entry><title>Lien non sécurisé</title><link href="http://example.org/b.html"/><updated>2026-10-30T13:15:00Z</updated></entry>
        </feed>
        """.utf8)
        let releases = try PressReleaseClient.parse(atom, feed: .ecb)
        #expect(releases.count == 1)
        #expect(releases.first?.link.host == "www.ecb.europa.eu")
    }

    @Test func entityDeclarationsAreRejected() {
        let hostile = Data(#"<?xml version="1.0"?><!DOCTYPE r [<!ENTITY x "y">]><rss><channel><item><title>&x;</title></item></channel></rss>"#.utf8)
        #expect(throws: PublicDataError.self) { try PressReleaseClient.parse(hostile, feed: .fed) }
    }
}
