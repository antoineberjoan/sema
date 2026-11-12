# Les données de départ restent écrites dans le code : un écart daté

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Sophos veut les valeurs hors du dossier de code : un dictionnaire de valeurs est une donnée du projet. Deux fichiers de sema portent des listes de départ écrites en Swift : `StatisticalStarter` (184 lignes de références de départ des sources statistiques) et `WebstatStarter` (les repères de départ de Webstat, avec les anciens identifiants).

## Décision

On garde ces deux listes dans le code pour l'instant. Elles ne changent pas la forme des connecteurs.

**Ce qui retire l'écart** : à la prochaine modification de ces valeurs, les passer en JSON dans `Resources/` et les lire par un fichier de décodage.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Passer les listes en JSON maintenant | Aucun écart | Un changement de chargement sans effet visible, non compilé, sur des valeurs que les préférences d'Antoine lisent déjà (`canonicalID`, `shortIDs`) |
| Garder le code, dater l'écart | Aucun risque pour les identifiants déjà enregistrés | Deux fichiers hors règle jusqu'à la prochaine modification |

## Conséquences

Les anciens identifiants de `WebstatStarter.shortIDs` ne changent pas : ils servent à relire les préférences que la personne a déjà sur son disque. Une migration de ce format serait une décision d'Antoine.

## Trace

Troisième lot des connecteurs. Remplace le point « données de départ » de l'ancienne décision sur les clients multi-services.
