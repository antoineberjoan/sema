// Choisit le rédacteur de la synthèse, gère la clé Claude et ne garde que les phrases vérifiées contre les faits.
import Foundation
import MarketCore

extension AppStore {
    static let claudeSourceID = "claude"

    var summaryWriter: SummaryWriter { SummaryWriter(rawValue: preferences.summaryWriterID ?? "") ?? .standard }
    func setSummaryWriter(_ writer: SummaryWriter) { mutatePreferences { $0.summaryWriterID = writer.rawValue } }

    var isAppleIntelligenceAvailable: Bool { AppleSummaryWriter.isAvailable }

    /// Why the chosen writer cannot write now, in words for the reader; nil when it can.
    var summaryBlocker: String? {
        switch summaryWriter {
        case .off: "La synthèse est désactivée. Choisissez un rédacteur dans Réglages, Sources."
        case .appleIntelligence: isAppleIntelligenceAvailable ? nil : AppleSummaryWriter.UnavailableError().errorDescription
        case .claude: hasClaudeKey ? nil : "Connectez votre clé Claude dans Réglages, Sources."
        }
    }

    func contextFacts(for series: MarketSeries, context: DayContext) -> [ContextFact] {
        ContextFact.facts(for: series, context: context) { MarketFormat.name(displayedSeries($0)) }
    }

    func cachedSummary(for series: MarketSeries) -> SummaryCheck? {
        Self.contextKey(series).flatMap { summaries["\($0)#\(summaryWriter.rawValue)"] }
    }

    /// Writes once per session and writer, then keeps only the sentences whose facts, figures and directions match.
    func summary(for series: MarketSeries, context: DayContext) async throws -> SummaryCheck {
        let writer = summaryWriter
        guard let key = Self.contextKey(series).map({ "\($0)#\(writer.rawValue)" }) else { throw AppleSummaryWriter.UnavailableError() }
        if let cached = summaries[key] { return cached }
        let facts = contextFacts(for: series, context: context)
        let draft: [SummarySentence]
        switch writer {
        case .off: return SummaryCheck([], facts: facts, day: context.day)
        case .appleIntelligence: draft = try await AppleSummaryWriter.write(facts: facts, day: context.day)
        case .claude:
            guard let apiKey = try await claudeKeychain.read() else { throw ClaudeClient.ClientError.rejectedKey }
            draft = try await ClaudeClient(key: apiKey).write(facts: facts, day: context.day)
        }
        let result = SummaryCheck(draft, facts: facts, day: context.day)
        summaries[key] = result
        return result
    }

    func checkClaudeKey() async {
        do { hasClaudeKey = try await claudeKeychain.read() != nil }
        catch { claudeError = "Le Trousseau n’a pas pu lire la clé Claude." }
    }

    func connectClaude(key: String) async -> Bool {
        guard !isConnectingClaude else { return false }
        isConnectingClaude = true; claudeError = nil
        defer { isConnectingClaude = false }
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await ClaudeClient(key: key).validateKey()
            try await claudeKeychain.save(key)
            hasClaudeKey = true
            return true
        } catch { claudeError = error.localizedDescription; return false }
    }

    func removeClaudeKey() async {
        guard !isConnectingClaude else { return }
        do {
            try await claudeKeychain.remove()
            hasClaudeKey = false; claudeError = nil
            summaries = summaries.filter { !$0.key.hasSuffix("#\(SummaryWriter.claude.rawValue)") }
        } catch { claudeError = "Le Trousseau n’a pas pu retirer la clé Claude." }
    }
}
