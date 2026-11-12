# Les jetons de design vivent dans un module à part

Date : 2026-11-12 · Statut : acceptée
Décidé par : Antoine

## Contexte

sema écrivait ses choix visuels à la main dans `Sources/SemaMac/DesignSystem/`. Sophos fabrique la sortie Swift des jetons, un fichier par famille de valeurs, dans un dossier propre à l'application. Les valeurs brutes y sont internes ; seuls les rôles sont publics, pour qu'une vue ne lise jamais une primitive. Cette règle n'a d'effet que si le design est un module à part. `AGENTS.md` demandait jusqu'ici un besoin explicite pour toute nouvelle cible.

## Décision

sema ajoute une cible SwiftPM, `SemaDesign`, dans `Sources/SemaDesign/`. Elle contient seulement la sortie fabriquée de `Resources/Brand/tokens.json`. L'app (`SemaMac`) en dépend ; le cœur (`MarketCore`) n'en dépend pas.

`Package.swift` peut changer pour cette cible, pour les ressources de tests et pour les exclusions de fichiers. Il ne change pour rien d'autre.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Une cible `SemaDesign` | Les primitives restent internes : une vue ne peut lire qu'un rôle | Une cible de plus à déclarer |
| La sortie dans `SemaMac` | Aucun changement de `Package.swift` | Une vue peut lire une primitive : la règle ne se contrôle plus |

## Conséquences

Les valeurs de couleur, d'espace, de forme, de texte et de mouvement viennent de `tokens.json`. Personne ne modifie un fichier de `Sources/SemaDesign/` à la main : `jetons.mjs --verifier` refuse une sortie périmée.

## Trace

Lot 3 de l'alignement de sema sur Sophos. Décision d'Antoine du 2026-11-12 (« copie conforme de Sophos », cible `SemaDesign` autorisée).
