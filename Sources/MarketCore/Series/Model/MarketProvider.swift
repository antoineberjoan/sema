// Définit les sources de cours à clé personnelle et leurs points d’accès officiels.
import Foundation

public enum MarketProvider: String, Codable, CaseIterable, Identifiable, Sendable {
    case twelveData = "twelve-data"
    case alphaVantage = "alpha-vantage"
    public var id: String { rawValue }
    public var title: String { self == .twelveData ? "Twelve Data" : "Alpha Vantage" }
    public var signupURL: URL {
        URL(string: self == .twelveData ? "https://twelvedata.com/account/api-keys" : "https://www.alphavantage.co/support/#api-key")!
    }
    public var website: URL {
        URL(string: self == .twelveData ? "https://twelvedata.com" : "https://www.alphavantage.co")!
    }
    public var quota: String { self == .twelveData ? "Basic : 8 crédits/minute, 800/jour." : "Gratuit : 25 appels/jour, catalogue et aperçus compris." }
}
