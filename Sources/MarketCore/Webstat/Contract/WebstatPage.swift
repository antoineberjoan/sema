// Page de résultats renvoyée par une recherche paginée.
import Foundation

public struct WebstatPage<Item: Sendable>: Sendable {
    public let items: [Item]
    public let total: Int
    public let offset: Int
    public var hasMore: Bool { offset + items.count < total }
}
