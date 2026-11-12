// Façon unique d'envoyer une requête à un fournisseur de cours, sans cache, sans cookie et sans redirection.
import Foundation

enum MarketDataTransport {
    private static let timeout: TimeInterval = 30

    private final class RedirectBlocker: NSObject, URLSessionTaskDelegate, Sendable {
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                        completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
            completionHandler(nil)
        }
    }

    static func makeSession() -> URLSession {
        // Aucune URL authentifiée ne doit être écrite dans le cache HTTP.
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil; configuration.httpCookieStorage = nil
        return URLSession(configuration: configuration, delegate: RedirectBlocker(), delegateQueue: nil)
    }

    static func request(host: String, endpoint: String, query: [String: String]) -> URLRequest {
        var components = URLComponents(string: host)!
        components.path = "/" + endpoint
        components.queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.timeoutInterval = timeout
        return request
    }

    /// Envoie la requête et rend le corps. Les erreurs ne contiennent ni adresse, ni clé, ni réponse brute.
    static func send(_ request: URLRequest, on session: URLSession) async throws -> Data {
        do {
            let (body, response) = try await session.data(for: request)
            try Task.checkCancellation()
            guard let response = response as? HTTPURLResponse else { throw MarketDataError.invalidData }
            if response.statusCode == 401 { throw MarketDataError.invalidKey }
            if response.statusCode == 403 { throw MarketDataError.entitlement }
            if response.statusCode == 429 { throw MarketDataError.quota }
            guard (200..<300).contains(response.statusCode) else {
                if let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] { try MarketDataFormat.checkError(data) }
                throw MarketDataError.network
            }
            return body
        } catch is CancellationError { throw CancellationError() }
        catch let error as MarketDataError { throw error }
        catch { throw MarketDataError.network }
    }

    /// Lit un corps JSON et refuse une erreur annoncée avec un code 200.
    static func object(_ body: Data) throws -> [String: Any] {
        guard let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { throw MarketDataError.invalidData }
        try MarketDataFormat.checkError(data)
        return data
    }
}
