// Phrase d’ouverture de « Aujourd’hui » : combien de repères sont sortis de l’habituel et dans quel sens, sans chiffre ni cause, écrite par des règles fixes.
import Foundation

public enum SessionSentence {
    public static func text(moves: [PeerMove], name: (MarketSeries) -> String) -> String {
        let rising = moves.filter { $0.change > 0 }.map { name($0.series) }
        let falling = moves.filter { $0.change < 0 }.map { name($0.series) }
        let count = rising.count + falling.count
        guard count > 0 else { return "Aucun de vos repères n’est sorti de l’habituel." }
        let lead = count == 1 ? "Un de vos repères est sorti de l’habituel" : "\(count) de vos repères sont sortis de l’habituel"
        let parts = [(rising, "en hausse"), (falling, "en baisse")].filter { !$0.0.isEmpty }.map { join($0.0) + " " + $0.1 }
        return lead + " : " + parts.joined(separator: " ; ") + "."
    }

    private static func join(_ names: [String]) -> String {
        guard let last = names.last, names.count > 1 else { return names.first ?? "" }
        return names.dropLast().joined(separator: ", ") + " et " + last
    }
}
