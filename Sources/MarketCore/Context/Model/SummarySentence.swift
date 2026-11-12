// Phrase d’une synthèse rédigée et identifiants des faits qu’elle cite.
import Foundation

public struct SummarySentence: Codable, Equatable, Sendable {
    public let text: String
    public let factIDs: [String]

    public init(text: String, factIDs: [String]) { self.text = text; self.factIDs = factIDs }

    enum CodingKeys: String, CodingKey { case text, factIDs = "facts" }
}
