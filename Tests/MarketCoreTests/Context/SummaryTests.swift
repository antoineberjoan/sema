// Vérifie le garde-fou de la synthèse (faits cités, chiffres, sens, causes), les faits numérotés et la réponse de Claude.
import Foundation
import Testing
@testable import MarketCore

struct SummaryTests {
    private let day = ISO8601DateFormatter().date(from: "2026-11-05T21:00:00Z")!
    private let facts = [
        ContextFact(id: "f1", kind: .move, label: "S&P 500",
                    text: "S&P 500 : −4,4 % sur la séance du 5 novembre 2026, soit 3,1 fois sa variation habituelle.", direction: .fall),
        ContextFact(id: "f2", kind: .peer, label: "VIX", text: "VIX : +70,2 % le même jour, soit 4,0 fois sa variation habituelle.", direction: .rise),
        ContextFact(id: "f3", kind: .headline, label: "example.com", text: "Titre publié par example.com : « Nvidia falls 9.3% »."),
    ]

    private func check(_ text: String, _ ids: [String]) -> SummaryCheck {
        SummaryCheck([SummarySentence(text: text, factIDs: ids)], facts: facts, day: day)
    }

    @Test func sentencesWithCitedFiguresAndDirectionsAreKept() {
        #expect(check("Le S&P 500 recule de 4,4 % le 5 novembre.", ["f1"]).kept.count == 1)
        #expect(check("Dans le même temps, le VIX bondit d’environ 70 %.", ["f2"]).kept.count == 1)
        #expect(check("Un titre indique que Nvidia perd 9,3 % le même jour.", ["f3", "f1"]).kept.count == 1)
    }

    @Test func inventedOrChangedFiguresAreHidden() {
        let result = check("Le S&P 500 chute de 5 %.", ["f1"])
        #expect(result.kept.isEmpty)
        #expect(result.hiddenCount == 1)
        #expect(check("Le VIX monte de 70,2 % et Nvidia de 12 %.", ["f2"]).kept.isEmpty)
        #expect(check("Le S&P 500 recule de 4,4 % le 6 novembre.", ["f1"]).kept.isEmpty)
    }

    @Test func directionMustMatchACitedFact() {
        #expect(check("Le S&P 500 progresse de 4,4 %.", ["f1"]).kept.isEmpty)
        #expect(check("Nvidia perd 9,3 % selon un titre.", ["f3"]).kept.isEmpty)
    }

    @Test func unknownMissingOrCausalCitationsAreHidden() {
        #expect(check("Le S&P 500 recule de 4,4 %.", ["f9"]).kept.isEmpty)
        #expect(check("Le S&P 500 recule de 4,4 %.", ["f1", "f9"]).kept.isEmpty)
        #expect(check("Le S&P 500 recule de 4,4 %.", []).kept.isEmpty)
        #expect(check("Le S&P 500 recule de 4,4 % à cause de Nvidia.", ["f1", "f3"]).kept.isEmpty)
        #expect(check("Le S&P 500 recule de 4,4 % en raison d’un titre.", ["f1", "f3"]).kept.isEmpty)
    }

    @Test func atMostThreeSentencesAreShown() {
        let draft = Array(repeating: SummarySentence(text: "Le S&P 500 recule de 4,4 %.", factIDs: ["f1"]), count: 4)
        let result = SummaryCheck(draft, facts: facts, day: day)
        #expect(result.kept.count == SummaryCheck.maximumSentences)
        #expect(result.hiddenCount == 1)
    }

    @Test func numbersReadFrenchDecimalsAndThousands() {
        let numbers = SummaryCheck.numbers(in: "6\u{202F}812,5 points, puis 4.4 et 70").map(\.value)
        #expect(numbers == [6812.5, 4.4, 70])
    }

    @Test func factsStartWithTheMoveOfTheSeries() throws {
        var values: [Decimal] = [100]
        for index in 0..<UnusualMove.window { values.append(values[values.count - 1] * (index.isMultiple(of: 2) ? 1.01 : 0.99)) }
        values.append(values[values.count - 1] * 0.96)
        let start = Date(timeIntervalSince1970: 1_792_022_400)
        let spy = MarketSeries(id: "spy", name: "SPY", subtitle: "Fixture", category: .markets, unit: .number, source: "Test",
                               observations: values.enumerated().map {
            MarketObservation(date: start.addingTimeInterval(Double($0.offset) * .day), value: $0.element)
        })
        var context = DayContext(day: try #require(spy.latest?.date))
        context.headlines = [Headline(title: "Stocks slide", link: URL(string: "https://example.com/a")!, publisher: "example.com", publishedAt: context.day)]
        let result = ContextFact.facts(for: spy, context: context, name: \.name)
        #expect(result.map(\.id) == ["f1", "f2"])
        #expect(result.first?.kind == .move)
        #expect(result.first?.direction == .fall)
        #expect(result.first?.text.contains("fois sa variation habituelle") == true)
        #expect(result.last?.link?.host == "example.com")
    }

    @Test func claudeAnswerIsReadAndRefusalsAreReported() throws {
        let answer = #"{"content":[{"type":"text","text":"{\"sentences\":[{\"text\":\"Le S&P 500 recule de 4,4 %.\",\"facts\":[\"f1\"]}]}"}],"stop_reason":"end_turn"}"#
        #expect(try ClaudeClient.parse(Data(answer.utf8)) == [SummarySentence(text: "Le S&P 500 recule de 4,4 %.", factIDs: ["f1"])])
        #expect(throws: ClaudeClient.ClientError.refused) {
            try ClaudeClient.parse(Data(#"{"content":[],"stop_reason":"refusal"}"#.utf8))
        }
        #expect(throws: ClaudeClient.ClientError.invalidData) { try ClaudeClient.parse(Data("{}".utf8)) }
    }

    @Test func claudeRequestKeepsTheKeyInItsHeader() throws {
        let request = try ClaudeClient(key: "test-key").request(facts: facts, day: day)
        #expect(request.url?.query == nil)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "test-key")
        let body = try #require(request.httpBody.flatMap { String(data: $0, encoding: .utf8) })
        #expect(body.contains("json_schema"))
        #expect(body.contains("f2 · VIX"))
        #expect(!body.contains("test-key"))
    }

    @Test func summaryIsOffByDefault() {
        #expect(SummaryWriter(rawValue: AppPreferences().summaryWriterID ?? "") ?? .standard == .off)
    }
}
