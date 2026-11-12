// Source des titres d’actualité choisie dans les réglages : GDELT sans clé, Alpha Vantage avec la clé existante, ou aucune.
import Foundation

public enum HeadlineSource: String, CaseIterable, Codable, Identifiable, Sendable {
    case gdelt, alphaVantage = "alpha-vantage-news", none
    public static let standard = HeadlineSource.gdelt
    public var id: String { rawValue }
    public var title: String {
        switch self { case .gdelt: "GDELT · sans clé"; case .alphaVantage: "Alpha Vantage News · votre clé"; case .none: "Aucune" }
    }
}
