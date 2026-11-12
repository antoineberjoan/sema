# Le verre du bandeau garde un noir et des blancs écrits : un écart daté

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Sophos veut qu'aucune couleur ne soit écrite dans une vue. Trois endroits de sema écrivent encore `.black` ou `.white` : le fond noir sous le dégradé de la signature du bandeau, la lumière et le voile de la matière des cartes du bandeau (`RibbonSurface`), et l'image de la barre des menus.

## Décision

- **Image de la barre des menus** : sans objet. L'image est un modèle (`isTemplate`) : macOS n'en lit que la transparence. Le noir est un masque, pas une couleur de design.
- **Fond noir de la signature et lumière du verre** : écart. Le patron n'a pas de rôle « fond sous un dégradé » ni « lumière d'une matière translucide ». Les opacités sont déjà des rôles de sema ou des réglages de la personne ; seules les couleurs de base restent écrites.

**Ce qui retire l'écart** : un rôle de couleur du patron pour une matière translucide (lumière et voile), ou, au prochain chantier visuel du bandeau, la création de deux rôles de sema dans `tokens.json` avec leurs contrastes mesurés.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Écrire deux rôles de couleur de sema maintenant | Aucun écart | Des couleurs claires et sombres à choisir et à mesurer sur le verre réel, sans Mac |
| Garder le noir et les blancs, dater l'écart | Aucun changement visible | Trois lignes de couleur écrites dans une vue |

## Trace

Dernier reste de la consigne de l'architecte sur la signature du bandeau : `on-accent` et les six opacités sont appliqués ; ces trois couleurs ne le sont pas.
