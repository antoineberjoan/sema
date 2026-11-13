// Demande à l’API Claude, avec la clé de l’utilisateur, une synthèse JSON des faits numérotés d’une séance.
import Foundation

public struct ClaudeClient: Sendable {
    static let messagesURL = URL(string: "https://api.anthropic.com/v1/messages")!
    static let modelsURL = URL(string: "https://api.anthropic.com/v1/models")!
    static let apiVersion = "2026-10-21"
    /// Repli côté serveur quand le modèle refuse : l’API relance la requête sur le modèle qu’elle recommande.
    static let fallbackBeta = "server-side-fallback-2026-07-01"
    static let model = "claude-opus-5-5"
    static let effort = "low"
    static let maximumTokens = 8000
    static let timeout: TimeInterval = 90

    public enum ClientError: Error, LocalizedError, Equatable {
        case rejectedKey, refused, incomplete, unavailable, invalidData
        public var errorDescription: String? {
            switch self {
            case .rejectedKey: "Claude refuse cette clé. Vérifiez-la dans la console Anthropic."
            case .refused: "Claude a décliné cette demande. Les faits restent affichés."
            case .incomplete: "La synthèse a été coupée avant la fin. Réessayez."
            case .unavailable: "Claude ne répond pas pour l’instant. Réessayez plus tard."
            case .invalidData: "La réponse de Claude est illisible. Aucune phrase n’est affichée."
            }
        }
    }

    private let key: String
    public init(key: String) { self.key = key }

    /// Un appel Messages ; la clé voyage dans son en-tête seulement.
    public func request(facts: [ContextFact], day: Date) throws -> URLRequest {
        var request = signed(URLRequest(url: Self.messagesURL))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(Self.fallbackBeta, forHTTPHeaderField: "anthropic-beta")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": Self.model,
            "max_tokens": Self.maximumTokens,
            "fallbacks": "default",
            "system": SummaryPrompt.instructions,
            "messages": [["role": "user", "content": SummaryPrompt.facts(facts, day: day)]],
            "output_config": ["effort": Self.effort, "format": ["type": "json_schema", "schema": Self.schema]],
        ] as [String: Any])
        return request
    }

    public func write(facts: [ContextFact], day: Date) async throws -> [SummarySentence] {
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request(facts: facts, day: day))
        try Self.check(response)
        return try Self.parse(data)
    }

    /// Liste les modèles, un appel gratuit qui distingue une clé valide d’une clé rejetée.
    public func validateKey() async throws {
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (_, response) = try await session.data(for: signed(URLRequest(url: Self.modelsURL)))
        try Self.check(response)
    }

    public static func parse(_ data: Data) throws -> [SummarySentence] {
        guard let message = try? JSONDecoder().decode(Message.self, from: data) else { throw ClientError.invalidData }
        switch message.stopReason {
        case "refusal": throw ClientError.refused
        case "max_tokens": throw ClientError.incomplete
        default: break
        }
        guard let text = message.content.first(where: { $0.type == "text" })?.text,
              let draft = try? JSONDecoder().decode(Draft.self, from: Data(text.utf8)) else { throw ClientError.invalidData }
        return draft.sentences
    }

    private func signed(_ request: URLRequest) -> URLRequest {
        var request = request
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = Self.timeout
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        return request
    }

    private static func check(_ response: URLResponse) throws {
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200: return
        case 401, 403: throw ClientError.rejectedKey
        default: throw ClientError.unavailable
        }
    }

    /// Calculé, car un dictionnaire de `Any` ne peut pas être partagé entre tâches.
    private static var schema: [String: Any] { [
        "type": "object", "additionalProperties": false, "required": ["sentences"],
        "properties": ["sentences": [
            "type": "array",
            "items": [
                "type": "object", "additionalProperties": false, "required": ["text", "facts"],
                "properties": ["text": ["type": "string"], "facts": ["type": "array", "items": ["type": "string"]]],
            ] as [String: Any],
        ] as [String: Any]],
    ] }

    private struct Message: Decodable {
        struct Block: Decodable { let type: String; let text: String? }
        let content: [Block]
        let stopReason: String?
        enum CodingKeys: String, CodingKey { case content, stopReason = "stop_reason" }
    }

    private struct Draft: Decodable { let sentences: [SummarySentence] }
}
