// Garde-fou de la synthèse : une phrase n’est gardée que si ses faits existent, ses chiffres et son sens s’y retrouvent, sans cause affirmée.
import Foundation

public struct SummaryCheck: Equatable, Sendable {
    public static let maximumSentences = 3

    public let kept: [SummarySentence]
    /// Sentences written but not shown, so the reader knows the summary is partial.
    public let hiddenCount: Int

    private static let riseWords: Set<String> = [
        "hausse", "hausses", "monte", "montent", "progresse", "progressent", "progression", "grimpe", "grimpent",
        "bondit", "bondissent", "bond", "rebondit", "rebond", "gagne", "gagnent", "envole", "envolent",
        "augmente", "augmentent", "remonte", "remontent",
    ]
    private static let fallWords: Set<String> = [
        "baisse", "baisses", "recule", "reculent", "recul", "chute", "chutent", "perd", "perdent", "plonge", "plongent",
        "repli", "replie", "replient", "decroche", "decrochent", "glisse", "glissent", "diminue", "diminuent",
        "cede", "cedent", "flechit", "flechissent", "degringole", "degringolent",
    ]
    /// Causal phrasing, folded: sema shows facts of the same day, never why.
    private static let causalMarkers = [
        "a cause d", "en raison d", "parce qu", "provoqu", "declench", "du fait d", "suite a", "a la suite d",
        "entrain", "s'expliqu", "grace a",
    ]

    /// Verifies each sentence against the facts it cites. Numbers may be rounded, never changed.
    /// The session date is not a figure; digits of fact labels (« S&P 500 ») are always allowed.
    public init(_ draft: [SummarySentence], facts: [ContextFact], day: Date) {
        let byID = Dictionary(facts.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let common = facts.flatMap { Self.numbers(in: $0.label) }
        let figures = { (text: String) in Self.numbers(in: Self.withoutSessionDate(text, day: day)) }
        var kept: [SummarySentence] = []
        var hidden = 0
        for sentence in draft {
            let text = sentence.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let cited = sentence.factIDs.compactMap { byID[$0] }
            guard kept.count < Self.maximumSentences, !text.isEmpty, !cited.isEmpty, cited.count == sentence.factIDs.count,
                  Self.numbersMatch(figures(text), allowed: common + cited.flatMap { figures($0.text) }),
                  Self.directionsMatch(text, cited: cited), !Self.affirmsCause(text) else { hidden += 1; continue }
            kept.append(SummarySentence(text: text, factIDs: sentence.factIDs))
        }
        self.kept = kept
        hiddenCount = hidden
    }

    private static func numbersMatch(_ written: [(value: Decimal, digits: Int)], allowed: [(value: Decimal, digits: Int)]) -> Bool {
        written.allSatisfy { written in
            allowed.contains { rounded($0.value, digits: written.digits) == written.value }
        }
    }

    private static func directionsMatch(_ text: String, cited: [ContextFact]) -> Bool {
        let words = Set(fold(text).split { !$0.isLetter }.map(String.init))
        let directions = Set(cited.compactMap(\.direction))
        if !words.isDisjoint(with: riseWords), !directions.contains(.rise) { return false }
        if !words.isDisjoint(with: fallWords), !directions.contains(.fall) { return false }
        return true
    }

    private static func affirmsCause(_ text: String) -> Bool {
        let folded = fold(text).replacingOccurrences(of: "’", with: "'")
        return causalMarkers.contains { folded.contains($0) }
    }

    /// Removes « 5 novembre 2026 », « 5 novembre » and « 1er novembre »: any other date keeps its digits and must match a fact.
    private static func withoutSessionDate(_ text: String, day: Date) -> String {
        let parts = ContextFact.longDate(day).split(separator: " ").map(String.init)
        guard parts.count == 3 else { return text }
        let days = parts[0] == "1" ? ["1er", "1"] : [parts[0]]
        let forms = days.flatMap { ["\($0) \(parts[1]) \(parts[2])", "\($0) \(parts[1])"] }
        return forms.reduce(text) { $0.replacingOccurrences(of: $1, with: " ", options: [.caseInsensitive, .diacriticInsensitive]) }
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .french)
    }

    private static func rounded(_ value: Decimal, digits: Int) -> Decimal {
        var source = value, result = Decimal()
        NSDecimalRound(&result, &source, digits, .plain)
        return result
    }

    /// Unsigned numbers of a text, with « , » or « . » as decimal mark and narrow spaces between thousands.
    static func numbers(in text: String) -> [(value: Decimal, digits: Int)] {
        let characters = Array(text)
        var result: [(value: Decimal, digits: Int)] = []
        var current = "", digits = 0, isDecimal = false
        func isDigit(_ index: Int) -> Bool { characters.indices.contains(index) && characters[index].isASCII && characters[index].isNumber }
        func flush() {
            if let value = Decimal(string: current) { result.append((value, digits)) }
            current = ""; digits = 0; isDecimal = false
        }
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if isDigit(index) {
                current.append(character)
                if isDecimal { digits += 1 }
            } else if !current.isEmpty, !isDecimal, character == "," || character == ".", isDigit(index + 1) {
                current.append("."); isDecimal = true
            } else if !current.isEmpty, !isDecimal, character == "\u{202F}" || character == "\u{00A0}",
                      isDigit(index + 1), isDigit(index + 2), isDigit(index + 3), !isDigit(index + 4) {
                // Thousands separator: the next three digits belong to the same number.
            } else if !current.isEmpty {
                flush()
            }
            index += 1
        }
        if !current.isEmpty { flush() }
        return result
    }
}
