# L'écran Bandeau lit les rôles de sens et garde le blanc de la signature

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Le bandeau est la première des surfaces translucides de sema (liste fermée, décision sur les surfaces translucides). Ses cartes sont sur du verre. La signature est un dégradé d'accent avec du texte blanc.

## Décision

- **Les écarts et les marges** lisent les rôles de sens. L'écart entre deux cartes reste de 12 points (`field-gap`) : il entre dans le calcul du nombre de cartes visibles, et un écart de 16 points en ferait perdre une sur un petit écran. Le rôle `item-gap` (16 points) aurait été le plus proche du sens ; il n'est pas choisi pour ne pas changer ce nombre.
- **Les fonds de repos** sur le verre (badge de comparaison d'une carte, bande des jours de la carte Agenda) lisent la couleur du texte à l'opacité `glass-rest`. Ce sont deux des fonds prévus par la décision sur les surfaces translucides.
- **Le jour choisi** dans la bande de la carte Agenda lit `selection`, comme dans l'écran Brief.
- **Le texte secondaire** des cartes garde le style système (surface translucide). Le texte très atténué (`tertiary`) devient aussi `secondary` : sur du verre, le patron n'a qu'un niveau.
- **La signature lit `on-accent` et des rôles d'opacité de sema.** Le texte, le tracé et le bord, posés sur un dégradé fait de pas de l'accent, lisent `on-accent`, le rôle « texte posé sur un aplat d'accent ». Les opacités du dégradé et du texte sont six rôles de `tokens.json` (`opacity.signature-…`). La mesure de contraste de Sophos ne couvre pas un dégradé : le contraste des deux extrémités est à regarder sur le Mac, en clair et en sombre.
- **Les icônes et le texte d'accent** (étoile du bandeau vide, flèche et titres de la carte Agenda) lisent `accent-text`.
- **Le rayon** d'une carte est `card` (16 points) ; le bord clair du verre mesure `border.width`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Lire les rôles, garder le blanc de la signature | Le bandeau lit les jetons là où le verre le permet | Un blanc propre à sema dans la signature |
| Tout lire dans les jetons | Aucun écart | Un texte de la signature sans contraste garanti sur le dégradé |

## Conséquences

La carte Agenda change d'apparence en même temps que l'écran Brief : les deux lisent les mêmes fonctions de ligne. Le composant de verre (`RibbonSurface`) lit les rayons et le contour du patron mais garde ses opacités de verre, propres à la décision sur le verre du bandeau.

## Trace

Septième lot d'écran de l'alignement de sema sur Sophos.
