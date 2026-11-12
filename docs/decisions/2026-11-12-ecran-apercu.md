# L'écran Aperçu lit les rôles de sens, avec neuf choix à relire

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

L'écran Aperçu est le troisième à lire les jetons de Sophos. Il contient le détail d'une série, le sélecteur Focus, l'inspecteur « Pourquoi ce mouvement ? », les onglets de période et les deux boutons d'icône (favori, sens de la parité). Neuf lectures n'ont pas de rôle exact.

## Décision

- **Le nom, la valeur et la variation d'un bloc** lisent `title-gap` (4 points), comme la tuile de l'écran Favoris : valeur de la série, tuile du sélecteur Focus, titre et date de l'inspecteur, unité à côté du chiffre. Le sélecteur Focus passe de 16 à 4 points entre le nom et la valeur.
- **Les marges d'un panneau de lecture** (l'inspecteur) lisent `page-inset-narrow` (32 points) et non 24. La marge de 48 points du sélecteur Focus lit `page-inset-wide` (64 points).
- **Entre deux éléments d'une même ligne ou d'un même bloc de contrôles** (pairs de l'inspecteur, bouton de synthèse, alertes, titres en en-tête), le rôle est `field-gap` (12 points) et non 8.
- **Les tuiles du sélecteur Focus** lisent `item-gap` (16 points) entre elles et le rayon `block` (10 points). Le cadre du sélecteur lit le rayon `window` (14 points).
- **Le contour du sélecteur Focus** lit `rule` : l'opacité 0,08 puis 0,6 en contraste augmenté disparaît, le rôle a déjà sa variante forte. Le contour de la tuile choisie lit `accent` plein (1 point), sans opacité à 0,6.
- **Le badge de variation** lit `accent-text` pour le texte et `selection` pour le fond. Le fond reste à 12 % en clair et passe à 24 % en sombre.
- **Le texte secondaire de la tuile du sélecteur Focus** garde le style système : le sélecteur est sur la liste fermée des surfaces translucides.
- **La zone `VStack` à un seul enfant du sélecteur Focus** disparaît avec son écart de 12 points : il n'avait aucun effet.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Aucune valeur recopiée ; un accent lisible en texte ; le contraste augmenté pris en charge par les rôles | Des écarts plus grands à 12 ou 16 points, une tuile du sélecteur plus basse de 24 points |
| Garder les valeurs actuelles | Aucun changement visible | Des rôles propres à sema pour 2, 8, 10 et 24 points : un catalogue de cas |

## Conséquences

L'inspecteur est plus large de 16 points en marge (32 au lieu de 24 de chaque côté). Le sélecteur Focus s'éloigne de 16 points de plus du bord de la fenêtre.

## Trace

Troisième lot d'écran de l'alignement de sema sur Sophos.
