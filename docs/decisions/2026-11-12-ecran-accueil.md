# L'écran d'accueil lit les rôles de sens, avec cinq choix à relire

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

L'écran d'accueil est le deuxième à lire les jetons de Sophos à la place des valeurs de l'ancien design. Cinq lectures n'ont pas de rôle qui les dise exactement. Chacune change un peu l'écran.

## Décision

- **Les tuiles de thème** lisent le rayon `block` (10 points) et non `card` (16 points). Une tuile de 64 points de haut est une petite carte. Le patron fait grandir le rayon avec la surface.
- **Le contour d'une tuile choisie** lit `border.width` (1 point) et non 1,5 point. Le choix reste lisible : fond de sélection, contour d'accent et coche.
- **Les points de progression** lisent `icon.gap` (8 points) entre eux. Le point inactif lit `rule-hover`, une teinte décorative. Aucun rôle ne dit « point d'étape ».
- **Le cercle vide d'une tuile non choisie** lit `text-muted`. Il porte un état : il doit rester visible.
- **Les icônes de section** lisent `accent-text` et non `accent`. Une icône de cette taille est un petit élément coloré. Le signe de la marque et les aplats gardent `accent`.
- **Le cadre vide de l'aperçu** lit `surface`. Cette zone est dans une fenêtre opaque : la liste fermée des surfaces translucides ne la contient pas.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire le rôle par son sens | Aucune valeur recopiée ; des rayons et des contours qui suivent le patron | Les tuiles sont plus arrondies à 10 points qu'à 16, et leur contour plus fin |
| Garder les valeurs actuelles | Aucun changement visible | Des rôles propres à sema pour 1,5 point et pour un rayon de tuile : un catalogue de cas |

## Conséquences

Les écarts passent de 10 ou 12 points à 12 ou 16 points (grille, tuiles, aperçu), et de 32 à 48 points entre les blocs de la bienvenue. Le point d'étape reste approximatif jusqu'à ce qu'un second écran en ait besoin.

## Trace

Deuxième lot d'écran de l'alignement de sema sur Sophos.
