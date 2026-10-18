// Sens d’un franchissement de seuil et ses libellés.
import Foundation

public enum AlertDirection: String, Codable, CaseIterable, Sendable {
    case fall, rise
    public var title: String { self == .fall ? "Baisse" : "Hausse" }
    public var crossingTitle: String { self == .fall ? "Passe en dessous de" : "Passe au-dessus de" }
}
