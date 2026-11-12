# L'écran Aperçu lit les rôles de sens, avec neuf choix à relire

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

L'écran Aperçu lit les jetons de Sophos. Il contient le détail d'une série, le sélecteur Focus, l'inspecteur « Pourquoi ce mouvement ? », les onglets de période et les deux boutons d'icône (favori, sens de la parité). Neuf lectures n'ont pas de rôle exact.

## Décision

- **Le nom, la valeur et la variation d'un bloc** lisent `title-gap` (4 points), comme la tuile de l'écran Favoris : valeur de la série, tuile du sélecteur Focus, titre et date de l'inspecteur, unité à côté du chiffre.
- **Les marges d'un panneau de lecture** (l'inspecteur) lisent `page-inset-narrow` (32 points). La marge du sélecteur Focus lit `page-inset-wide` (64 points).
- **Entre deux éléments d'une même ligne ou d'un même bloc de contrôles** (pairs de l'inspecteur, bouton de synthèse, alertes, titres en en-tête), le rôle est `field-gap` (12 points).
- **Les tuiles du sélecteur Focus** lisent `item-gap` (16 points) entre elles et le rayon `block` (10 points). Le cadre du sélecteur lit le rayon `window` (14 points).
- **Le contour du sélecteur Focus** lit `rule`, qui a déjà sa variante forte en contraste augmenté. Le contour de la tuile choisie lit `accent` plein (1 point).
- **Le badge de variation** lit `accent-text` pour le texte et `selection` pour le fond. Le fond est à 12 % en clair et à 24 % en sombre.
- **Le texte secondaire de la tuile du sélecteur Focus** garde le style système : le sélecteur est sur la liste fermée des surfaces translucides.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Aucune valeur recopiée ; un accent lisible en texte ; le contraste augmenté pris en charge par les rôles | Des écarts de 12 ou 16 points |
| Écrire une valeur propre à sema | Des écarts sur mesure | Des rôles propres à sema pour 2, 8, 10 et 24 points : un catalogue de cas |

## Conséquences

L'inspecteur a une marge de 32 points de chaque côté. Le sélecteur Focus est à 64 points du bord de la fenêtre.
