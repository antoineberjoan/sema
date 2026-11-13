// Page de résultats renvoyée par une recherche paginée.
import Foundation

public struct WebstatPage<Item: Sendable>: Sendable {
    public let items: [Item]
    public let total: Int
    public let offset: Int
    public var hasMore: Bool { offset + items.count < total }

    /// Une page lue dans une liste déjà complète (l'export léger), pour continuer au-delà du plafond de la recherche paginée.
    public static func slice(of all: [Item], offset: Int, size: Int) -> WebstatPage {
        let end = min(offset + size, all.count)
        return WebstatPage(items: offset < end ? Array(all[offset..<end]) : [], total: all.count, offset: offset)
    }
}
