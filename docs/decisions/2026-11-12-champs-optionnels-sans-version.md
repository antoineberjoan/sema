# Un nouveau choix personnel est un champ optionnel du document v2, sans changement de version

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (reprise d'un document retiré)

## Contexte

Le fichier de préférences est déjà chez les personnes qui ont installé sema. Un changement de version ou de nom de clé casserait leurs choix.

## Décision

- Un nouveau choix est un champ optionnel du document v2, lu avec `decodeIfPresent`. Son absence garde le comportement précédent.
- Le document est écrit de manière atomique. Un fichier illisible n'est jamais remplacé en silence : l'erreur est visible.
- Le document v1 est lu, copié en `preferences.json.v1-backup`, puis migré. Favoris, règles, identifiants et points de départ gardent leur sens. La clé du Trousseau n'est jamais copiée.
- Une valeur inconnue (palette, mode, position du bandeau) se replie sur le défaut sans effacer les préférences.
- Les caches (séries, catalogues) sont séparés et peuvent être régénérés. `webstat-cache.json` garde son nom pour compatibilité.
- Les historiques sont immuables : une actualisation réussie fusionne les observations reçues. L'échec d'une série garde son historique.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Champs optionnels, une seule version | Aucune migration ; aucun choix perdu | Un document qui garde des champs historiques |
| Une nouvelle version à chaque ajout | Un format net | Une migration à chaque fois, et un risque de perte |

## Conséquences

Le test `PersistedFormatTests` fige les noms de clés. Une migration de format reste une décision d'Antoine.

## Trace

Repris de `docs/ARCHITECTURE.md` à son retrait, le 2026-11-12. La date d'origine n'est pas écrite : le texte complet reste dans l'historique Git.
