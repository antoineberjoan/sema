# La structure du code se contrôle par le bloc structure de la fiche

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Jusqu'ici, `scripts/guardrails.py` lisait `.agents/structure.json`, qui donnait une responsabilité à chaque dossier du dépôt. Sophos a une autre méthode : chaque sorte de code a une forme fermée, déclarée dans le bloc `structure:` de `projet.yml`, et `structure.mjs` refuse ce qui en sort.

## Décision

- Le contrôle de `structure.json` est retiré, avec le fichier.
- Le bloc `structure:` est posé dans `projet.yml` au premier lot de structure du code, avec un cliquet égal au nombre de fautes de ce jour. Le cliquet ne peut que baisser, jusqu'à zéro à la fin des lots de structure.
- **Entre le retrait et ce premier lot, rien n'est contrôlé** : aucune unité n'est déclarée, un fichier posé n'importe où n'est refusé par aucun contrôle de structure. Cet état est accepté pour ce seul intervalle.
- Les dossiers que la fiche ne déclare pas ne sont jamais contrôlés (la racine de l'app, les composants).

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Retirer l'ancien contrôle maintenant, déclarer au premier lot | Une seule méthode, celle de Sophos | Un intervalle sans contrôle de structure |
| Garder `structure.json` jusqu'à la déclaration | Aucun trou | Deux méthodes en même temps, et un fichier à retirer plus tard |

## Conséquences

Les contrôles qui restent pendant l'intervalle : secrets, marqueurs de conflit, descriptif en tête de fichier, imports interdits dans le cœur, valeurs visuelles en dur, un type par fichier, types inutilisés, miroir de release, JSON, liens.

## Trace

Retrait des anciens documents du 2026-11-12. Le comptage de départ (120 fautes pour les unités du cœur et des écrans) vient d'un essai de `structure.mjs` dans une copie du dépôt.
