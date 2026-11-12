# Le dossier des composants propres s'écrit en minuscules, contre la casse des dossiers Swift

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Le contrôle de Sophos cherche les composants propres dans un dossier `components/custom`, en minuscules, et vérifie l'en-tête de chaque fichier (la page suivie et la décision). La grammaire des noms veut un dossier Swift en `PascalCase`. Les deux ne tiennent pas ensemble : un dossier `Components/Custom` ne serait pas vu par le contrôle. Sur le disque d'un Mac, `Components` et `components` sont le même dossier : on ne peut pas garder les deux.

## Décision

- Les composants partagés de l'app vivent dans `Sources/SemaMac/components/`, en minuscules. Les composants propres ou qui reprennent un composant de la référence avec un écart sont dans `Sources/SemaMac/components/custom/`.
- Le contrôle de Sophos vérifie ainsi l'en-tête de ces fichiers : `@documentation` et `@decision`, et l'absence de couleur écrite en dur.
- Les dossiers `Components/` de chaque écran (module d'écran) gardent leur nom du patron et leur casse. Ils sont sous `Features/<Écran>/` : aucun conflit de casse avec `components/`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Dossier en minuscules | Le contrôle vérifie les en-têtes | Un dossier en minuscules dans un module en `PascalCase` |
| `Components/Custom` en `PascalCase` | La grammaire Swift suivie | Le contrôle ne voit rien : aucun en-tête vérifié |

## Conséquences

À demander à Sophos : une expression insensible à la casse pour trouver le dossier. Dès qu'elle existe, le dossier peut passer en `PascalCase` et cette décision se retire.

## Trace

Lot des composants de l'alignement de sema sur Sophos. Le contrôle (`socle.mjs`, `carte.mjs --verifier`) a refusé sept fichiers sans en-tête tant que le dossier était en minuscules : la vérification fonctionne.
