// Isole la lecture, l’écriture et la suppression de la clé personnelle dans le Trousseau macOS.
import Foundation
import Security

/// A device-local credential. Never copied into preferences, caches or the distributed app.
actor WebstatKeychain {
    private let service: String
    private let account = "api-key"

    init(service: String = (Bundle.main.bundleIdentifier ?? "com.antoineberjoan.sema") + ".webstat") {
        self.service = service
    }

    struct KeychainError: Error, LocalizedError {
        let status: OSStatus
        var errorDescription: String? {
            "Le Trousseau macOS n’a pas pu accéder à la clé Webstat (code \(status))."
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
            item[kSecAttrLabel as String] = "sema · clé personnelle Webstat"
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
