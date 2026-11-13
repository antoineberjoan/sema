# Le signe est une courbe en palier avec un point ; la palette sema est le thème par défaut

Date : 2026-11-08 · Statut : acceptée
Décidé par : Antoine

## Contexte

sema a une identité propre : le signe « repère », une palette de marque et six autres palettes au choix de la personne.

## Décision

- Le signe est une courbe qui monte puis se pose en palier, avec un point à la jonction détaché par un anneau de la couleur du fond. La géométrie est écrite une fois (`SignalPath.swift`) ; les SVG de `Resources/Brand/` en sont exportés.
- La palette **sema** est le thème par défaut des nouveaux profils. Six autres thèmes sont disponibles dans Réglages → Apparence ; un choix enregistré est conservé.
- Le nom s'écrit « sema », toujours en minuscules, y compris en début de phrase.
- L'icône de l'app suit les fichiers d'Antoine (`sema-app-icon.svg` et sa version sombre), sans suivre le thème personnel.
- La palette et le mode Système / Clair / Sombre sont deux choix indépendants, locaux et persistants, partagés par la fenêtre, les réglages et le bandeau.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Sept palettes, sema par défaut | Une marque nette ; aucun choix enregistré cassé | Sept palettes à tenir |
| Une seule palette | Moins de palettes | Casse les choix enregistrés |

## Conséquences

Les valeurs de couleur sont dans `Resources/Brand/tokens.json`. Les noms enregistrés des palettes ne changent jamais.
