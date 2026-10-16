import Foundation

/// Optional identity for this Mac. No account, network service or original photo metadata.
public struct LocalProfile: Codable, Equatable, Sendable {
    public var firstName: String
    public var lastName: String
    public var avatarJPEG: Data?

    public init(firstName: String = "", lastName: String = "", avatarJPEG: Data? = nil) {
        self.firstName = firstName; self.lastName = lastName; self.avatarJPEG = avatarJPEG
    }

    public var displayName: String {
        [firstName, lastName].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }.joined(separator: " ")
    }
    public var initials: String {
        [firstName, lastName].compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).first }
            .map { String($0).uppercased() }.joined()
    }
}
