// Unité dans laquelle une série publie ses valeurs, avec son symbole d’affichage.
import Foundation

public enum ValueUnit: String, Codable, Sendable {
    case percent, usd, jpy, chf, gbp, eur, index, number, unknown

    public var symbol: String {
        switch self {
        case .percent: "%"
        case .usd: "USD"
        case .jpy: "JPY"
        case .chf: "CHF"
        case .gbp: "GBP"
        case .eur: "€"
        case .index: "indice"
        case .number: ""
        case .unknown: "Unité non interprétée"
        }
    }
}
