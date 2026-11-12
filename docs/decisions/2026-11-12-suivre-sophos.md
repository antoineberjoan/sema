# Le projet suit Sophos

Date : 2026-11-12 · Statut : acceptée
Décidé par : Antoine

## Contexte

Sophos décrit une méthode commune à tous les projets d'Antoine : socle de fichiers, jetons de design, structure du code, contrôles et garde des agents. La fiche `projet.yml` déclare la version suivie.

## Décision

sema suit Sophos à l'identique. Seuls sont propres au projet : le nom, la marque (palettes, icône, police) et le comportement du produit.

- **Qui décide.** Les décisions vivent dans ce dépôt (`docs/decisions/`, `docs/fondation.md`).
- **Les sept palettes** (la marque et six autres) que la personne choisit dans les réglages sont un réglage visible du produit. Chaque palette est un jeu des mêmes rôles de couleur.
- **Les fichiers de la personne** gardent leurs noms, leurs clés et leurs valeurs, même si un type Swift est renommé.
- **Le code** s'écrit en anglais. L'interface et ce qu'un fichier persistant porte restent en français.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Suivre Sophos | Un seul système, le même dans tous les projets | Les écarts passent par une décision datée |
| Garder un système propre au projet | Une liberté locale | Deux systèmes à maintenir et des exceptions |

## Conséquences

Aucun alias, aucune couche de compatibilité, aucun code mort, aucune exception sans décision datée.
