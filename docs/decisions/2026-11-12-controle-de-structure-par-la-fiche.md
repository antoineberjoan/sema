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
| `structure.mjs` pour la structure, `guardrails.py` pour le reste | Un outil par sujet | Deux outils à lancer : `controler.sh` les lance tous |
| Des règles de structure propres à sema dans `guardrails.py` | Des règles locales | Deux méthodes pour le même sujet |

## Conséquences

`scripts/guardrails.py` porte les contrôles propres à sema : secrets, marqueurs de conflit, descriptif en tête de fichier, imports interdits dans le cœur, valeurs visuelles en dur, un type par fichier, types inutilisés, miroir de release, JSON, liens.
