// Vérifie la lecture des titres GDELT et Alpha Vantage, leur date UTC et le refus des liens non sécurisés.
import Foundation
import Testing
@testable import MarketCore

struct HeadlineTests {
    private func utc(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

    @Test func gdeltArticlesKeepTitleLinkPublisherAndDate() throws {
        let data = Data(#"{"articles":[{"url":"https://example.com/a","title":"Chip stocks drag Wall Street lower","seendate":"20261105T221500Z","domain":"example.com"},{"url":"http://example.com/b","title":"Non sécurisé","seendate":"20261105T221500Z"}]}"#.utf8)
        let headlines = try GDELTClient.parse(data)
        #expect(headlines.count == 1)
        #expect(headlines.first?.publisher == "example.com")
        #expect(headlines.first?.publishedAt == utc("2026-11-05T22:15:00Z"))
        #expect(try GDELTClient.parse(Data("{}".utf8)).isEmpty)
    }

    @Test func gdeltRequestCoversTheSessionWithoutKey() {
        let request = GDELTClient.request(from: utc("2026-11-05T00:00:00Z"), to: utc("2026-11-05T23:59:59Z"))
        let address = request.url?.absoluteString ?? ""
        #expect(address.contains("startdatetime=20261105000000"))
        #expect(address.contains("enddatetime=20261105235959"))
        #expect(!address.contains("key"))
    }

    @Test func alphaVantageFeedUsesItsOwnTimestamp() throws {
        let data = Data(#"{"items":"1","feed":[{"title":"Nvidia falls 9.3%","url":"https://example.com/n","time_published":"20261105T210000","source":"Example News"}]}"#.utf8)
        let headlines = try MarketDataClient.news(data)
        #expect(headlines.map(\.publisher) == ["Example News"])
        #expect(headlines.first?.publishedAt == utc("2026-11-05T21:00:00Z"))
    }
}
