// Flux publics des communiqués de banques centrales lus par sema, sans clé.
import Foundation

public enum CentralBankFeed: String, CaseIterable, Codable, Identifiable, Sendable {
    case fed = "fed-press", ecb = "ecb-press"
    public var id: String { rawValue }
    public var title: String {
        switch self { case .fed: "Réserve fédérale"; case .ecb: "BCE" }
    }
    public var url: URL {
        let address = switch self {
        case .fed: "https://www.federalreserve.gov/feeds/press_all.xml"
        case .ecb: "https://www.ecb.europa.eu/rss/press.html"
        }
        return URL(string: address)!
    }
}
