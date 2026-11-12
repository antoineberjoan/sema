// Fait passer un cache Webstat de schéma 1 (liste de séries sans version) au schéma 2.
import MarketCore

/// Retrait : voir `docs/decisions/2026-11-12-relecture-des-versions-de-fichiers.md`.
enum WebstatCacheMigration {
    static func upgrade(_ stored: [MarketSeries]) -> [MarketSeries] {
        stored.map { $0.withID(WebstatStarter.canonicalID($0.id)) }
    }
}
