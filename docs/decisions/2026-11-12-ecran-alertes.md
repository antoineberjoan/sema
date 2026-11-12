# L'écran Alertes lit les rôles de sens, avec quatre choix à relire

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

L'écran Alertes montre les repères surveillés, les seuils et le formulaire de création d'une règle. Quatre lectures n'ont pas de rôle exact.

## Décision

- **La feuille de création d'alerte** a une marge de 32 points (`page-inset-narrow`) et non 24 : une feuille est une page étroite. Les blocs de la feuille restent séparés de 24 points (`group-gap`).
- **Les champs du formulaire** sont séparés de 12 points (`field-gap`, 16 avant) : ce sont des champs d'un même bloc.
- **L'encadré « Surveiller vos favoris ? »** lit `surface` et le rayon `block`. Il lisait un fond à 3,5 % de la couleur du texte : cette zone est dans une fenêtre opaque, hors de la liste fermée des surfaces translucides.
- **La cloche d'une règle et le bouton « Surveillé »** lisent `accent-text` : ce sont une icône et un texte colorés.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Aucune valeur recopiée ; un texte coloré lisible | Une feuille plus large de 16 points, des champs plus serrés de 4 points |
| Garder les valeurs actuelles | Aucun changement visible | Des rôles propres à sema pour 14, 16 et 24 points |

## Conséquences

Les lignes de la liste gardent leurs écarts de 16 points entre éléments répétés et 4 points entre un nom et son texte (8 avant).

## Trace

Quatrième lot d'écran de l'alignement de sema sur Sophos.
