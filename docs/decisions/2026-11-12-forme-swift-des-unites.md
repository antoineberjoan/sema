# En Swift, un rôle à plusieurs types est un dossier, un rôle à un seul type est un fichier

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Sophos range chaque sorte de code selon une forme fermée : un rôle est le dernier mot du nom d'un fichier, ou le nom d'un dossier. Dans sema, `scripts/guardrails.py` impose un type visible par fichier, et un fichier porte le nom de son type. Un fichier `MarketSeries.swift` a pour rôle « series » : il n'est dans aucune forme.

## Décision

- Un rôle qui porte plusieurs types est un **dossier** du nom du rôle, avec un fichier par type : `Model/`, `Contract/`, `Schema/`, `Types/`.
- Un rôle qui porte un seul type est un **fichier** dont le nom finit par le rôle : `WebstatClient.swift`, `PreferencesRepository.swift`, `AlertsScreen.swift`.
- Les règles de calcul d'une étape sont dans un dossier `Calculations/`, un fichier par type, nommé comme son type. `guardrails.py` garde la règle d'origine : un type visible par fichier, nommé comme lui.
- Les dossiers sont en `PascalCase` ; l'outil de contrôle ignore la casse.
- Un déplacement de fichier ne change aucun nom public : tout `MarketCore` reste une seule cible. Un renommage de type change la surface publique, et `PublicSurfaceTests` est alors mis à jour exprès.
- Les fichiers de l'utilisateur (noms, clés, valeurs) ne changent jamais. `PersistedFormatTests` le garde.
- Les tests vivent dans `Tests/MarketCoreTests/<Unité>/`, au même chemin relatif que l'unité.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Dossier pour plusieurs types, fichier pour un seul | Les deux contrôles tiennent ensemble | Des dossiers de rôle (`Model/`) un peu plus profonds |
| Un fichier par rôle avec plusieurs types | Peu de fichiers | Refusé par le contrôle « un type par fichier » |
| Renoncer au contrôle « un type par fichier » | Aucune règle de plus | Un nom de type ne suffit plus à retrouver son fichier |
| Renommer les types de règle en `…Calculations` | Le fichier porte le rôle sans exception | Des noms publics qui changent et des centaines d'appels à réécrire |

## Conséquences

Le premier lot de structure pose le bloc `structure:` de `projet.yml` avec un cliquet égal au nombre de fautes de ce jour (121). Chaque lot qui range une unité baisse le cliquet ; il est à 0 à la fin.

## Trace

Premier lot de structure du code de l'alignement de sema sur Sophos. Le comptage vient de `structure.mjs` : 121 fautes pour les 17 unités déclarées.
