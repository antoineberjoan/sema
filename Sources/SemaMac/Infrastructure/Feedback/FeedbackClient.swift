// Résout et valide l’adresse du formulaire de retours depuis la configuration du bundle.
import Foundation

enum FeedbackClient {
    static var formURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "FeedbackFormURL") as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil else { return nil }
        return url
    }
}
