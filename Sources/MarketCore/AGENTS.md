# Cœur et données

Applicable aussi aux tests de `MarketCore`. Le cœur reste indépendant de SwiftUI, AppKit et UserNotifications.

- Chaque série porte origine, source, unité et dates d’observation. Les fixtures sont identifiées ; les devises BCE sont des références publiées, jamais des cours de trading en direct.
- Valeurs et variations financières en `Decimal`. Conversion en `Double` uniquement pour dessiner. Taux : points de pourcentage ; parités : pourcentage relatif.
- Une alerte cible une série par `seriesID`. Franchissement strict ; une même observation ne déclenche pas deux fois. Tester calculs et décodage dans `Tests/MarketCoreTests`.
- Préférences et alertes locales, versionnées, écrites atomiquement. Un fichier illisible reste intact et l’erreur est visible. Lire `docs/decisions/2026-10-15-preferences-et-cache-separes.md` avant un changement de persistance.
- Ne pas supprimer une migration tant que son usage et la préservation des données existantes ne sont pas établis. Ne pas développer deux comportements métier pour deux versions.
- Aucune clé fournisseur partagée, aucune clé personnelle dans le dépôt, une URL, un cache ou un log.
- Avant de changer une source, lire uniquement son contrat dans `docs/DATA-SOURCES.md`, `docs/PUBLIC-CATALOGUES.md` ou `docs/PERSONALIZATION.md`.
