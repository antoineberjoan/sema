// Rédige la synthèse avec le modèle d’Apple Intelligence, sur ce Mac et sans réseau, quand macOS 26 le propose.
import Foundation
import MarketCore
#if canImport(FoundationModels)
import FoundationModels
#endif

enum AppleSummaryWriter {
    struct UnavailableError: Error, LocalizedError {
        var errorDescription: String? {
            "Apple Intelligence n’est pas disponible sur ce Mac. Il faut macOS 26, un Mac compatible et Apple Intelligence activé dans Réglages Système."
        }
    }

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) { return SystemLanguageModel.default.isAvailable }
        #endif
        return false
    }

    static func write(facts: [ContextFact], day: Date) async throws -> [SummarySentence] {
        #if canImport(FoundationModels)
        if #available(macOS 26, *), SystemLanguageModel.default.isAvailable {
            let session = LanguageModelSession(instructions: SummaryPrompt.instructions)
            let response = try await session.respond(to: SummaryPrompt.facts(facts, day: day), generating: Draft.self)
            return response.content.sentences.map { SummarySentence(text: $0.text, factIDs: $0.facts) }
        }
        #endif
        throw UnavailableError()
    }
}

#if canImport(FoundationModels)
@available(macOS 26, *)
@Generable private struct Draft {
    @Guide(description: "Trois phrases au plus, en français simple.")
    var sentences: [DraftSentence]
}

@available(macOS 26, *)
@Generable private struct DraftSentence {
    @Guide(description: "Une phrase courte en français, avec les chiffres recopiés des faits.")
    var text: String
    @Guide(description: "Identifiants des faits cités, par exemple f1.")
    var facts: [String]
}
#endif
