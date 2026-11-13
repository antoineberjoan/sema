# Le bandeau et la fenêtre partagent un seul état

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Le bandeau des favoris et la fenêtre principale montrent les mêmes repères. Une action sur un favori doit se voir tout de suite dans les deux.

## Décision

- `AppStore` est l'unique état partagé et le point de coordination. Il ne dessine pas l'interface.
- Le bandeau et la fenêtre n'ont pas de deuxième sélection, de deuxième période ni de deuxième état métier.
- Le bandeau n'envoie aucune requête automatique. Le survol non plus.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Un seul état partagé | Une action visible partout, tout de suite | Un point de coordination à garder simple |
| Un état par surface | Des surfaces indépendantes | Des écarts entre le bandeau et la fenêtre |

## Conséquences

La règle de fil d'exécution (`MainActor`) est dans `Sources/SemaMac/AGENTS.md`.
