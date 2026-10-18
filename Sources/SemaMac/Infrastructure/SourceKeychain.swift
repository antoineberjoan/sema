// Isole la lecture, l’écriture et la suppression de la clé personnelle dans le Trousseau macOS.
import Foundation
import Security

/// A device-local credential. Never copied into preferences, caches or the distributed app.
actor SourceKeychain {
    private let service: String
    private let title: String
    private let account = "api-key"

    init(sourceID: String, title: String) {
        service = (Bundle.main.bundleIdentifier ?? "com.antoineberjoan.sema") + "." + sourceID
        self.title = title
    }

    struct KeychainError: Error, LocalizedError {
        let status: OSStatus
        var errorDescription: String? {
            "Le Trousseau macOS n’a pas pu accéder à la clé personnelle (code \(status))."
        }
    }

    func read() throws -> String? {
        var query = identity
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else { throw KeychainError(status: status) }
        return key
    }

    func save(_ key: String) throws {
        let attributes = [kSecValueData as String: Data(key.utf8)]
        var status = SecItemUpdate(identity as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = identity
            item[kSecValueData as String] = Data(key.utf8)
            item[kSecAttrLabel as String] = "sema · clé personnelle \(title)"
            status = SecItemAdd(item as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    func remove() throws {
        let status = SecItemDelete(identity as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status: status) }
    }

    private var identity: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service, kSecAttrAccount as String: account,
         kSecAttrSynchronizable as String: false]
    }
}
