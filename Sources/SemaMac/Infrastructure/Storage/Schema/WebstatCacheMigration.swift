// Fait passer les identifiants des séries d'un cache Webstat vers les codes de série ; un cache de schéma 1 (liste sans version) passe aussi par là.
import MarketCore

/// Retrait : voir `docs/decisions/2026-11-12-relecture-des-versions-de-fichiers.md`.
enum WebstatCacheMigration {
    static func upgrade(_ stored: [MarketSeries]) -> [MarketSeries] {
        stored.map { $0.withID(IdentifierMigration.upgrade($0.id)) }
    }
}
