import Foundation

enum SemaFeedback {
    static var formURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SemaFeedbackFormURL") as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil else { return nil }
        return url
    }
}
