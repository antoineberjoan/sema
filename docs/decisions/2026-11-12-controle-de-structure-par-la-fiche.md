# La structure du code se contrôle par le bloc structure de la fiche

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Chaque sorte de code a une forme fermée, déclarée dans le bloc `structure:` de `projet.yml`. `structure.mjs` refuse ce qui en sort.

## Décision

- Le bloc `structure:` de `projet.yml` déclare les unités, avec un cliquet égal au nombre de fautes. Le cliquet ne peut que baisser, jusqu'à zéro.
- Les dossiers que la fiche ne déclare pas ne sont jamais contrôlés (la racine de l'app, les composants).

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Un seul contrôle de structure, celui de Sophos | Une seule méthode | Aucune règle de structure propre à sema |
| Un contrôle propre au dépôt en plus | Des règles locales | Deux méthodes en même temps |

## Conséquences

`scripts/guardrails.py` garde les autres contrôles : secrets, marqueurs de conflit, descriptif en tête de fichier, imports interdits dans le cœur, valeurs visuelles en dur, un type par fichier, types inutilisés, miroir de release, JSON, liens.
