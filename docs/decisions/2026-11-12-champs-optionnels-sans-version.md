# Un nouveau choix personnel est un champ optionnel du document v2, sans changement de version

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Le fichier de préférences est déjà chez les personnes qui ont installé sema. Un changement de version ou de nom de clé casserait leurs choix.

## Décision

- Un nouveau choix est un champ optionnel du document v2, lu avec `decodeIfPresent`. Son absence garde le comportement précédent.
- Le document est écrit de manière atomique. Un fichier illisible n'est jamais remplacé en silence : l'erreur est visible.
- Un document de schéma 1 est relu par une étape isolée ([relecture des versions de fichiers](2026-11-12-relecture-des-versions-de-fichiers.md)). La clé du Trousseau n'est jamais copiée.
- Une valeur inconnue (palette, mode, position du bandeau) se replie sur le défaut sans effacer les préférences.
- Les caches (séries, catalogues) sont séparés et peuvent être régénérés. `webstat-cache.json` garde son nom : la personne l'a sur son disque.
- Les historiques sont immuables : une actualisation réussie fusionne les observations reçues. L'échec d'une série garde son historique.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Champs optionnels, une seule version | Aucune migration ; aucun choix perdu | Un document qui garde des champs historiques |
| Une nouvelle version à chaque ajout | Un format net | Une migration à chaque fois, et un risque de perte |

## Conséquences

Le test `PersistedFormatTests` fige les noms de clés. Une migration de format reste une décision d'Antoine.
