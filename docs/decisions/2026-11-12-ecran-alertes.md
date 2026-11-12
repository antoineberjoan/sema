# L'écran Alertes lit les rôles de sens, avec quatre choix à relire

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

L'écran Alertes montre les repères surveillés, les seuils et le formulaire de création d'une règle. Quatre lectures n'ont pas de rôle exact.

## Décision

- **La feuille de création d'alerte** a une marge de 32 points (`page-inset-narrow`) : une feuille est une page étroite. Les blocs de la feuille sont séparés de 24 points (`group-gap`).
- **Les champs du formulaire** sont séparés de 12 points (`field-gap`) : ce sont des champs d'un même bloc.
- **L'encadré « Surveiller vos favoris ? »** lit `surface` et le rayon `block`. Cette zone est dans une fenêtre opaque, hors de la liste fermée des surfaces translucides.
- **La cloche d'une règle et le bouton « Surveillé »** lisent `accent-text` : ce sont une icône et un texte colorés.
- **Les lignes de la liste** sont séparées de 16 points entre éléments répétés et de 4 points entre un nom et son texte.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Aucune valeur recopiée ; un texte coloré lisible | Une feuille large (marge de 32 points) |
| Écrire une valeur propre à sema | Des marges et des écarts sur mesure | Des rôles propres à sema pour 14, 16 et 24 points |

## Conséquences

Aucune valeur de marge ni d'écart n'est écrite dans l'écran : `guardrails.py` le contrôle.
