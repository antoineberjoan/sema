// Décrit l’identité locale facultative, sans compte ni métadonnées de photo originales.
import Foundation

/// Identité facultative pour ce Mac. Pas de compte, de service réseau ni de métadonnées de la photo d’origine.
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
