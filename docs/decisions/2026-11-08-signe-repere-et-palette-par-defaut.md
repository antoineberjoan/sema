# Le signe est une courbe en palier avec un point ; la palette sema est le thème par défaut

Date : 2026-11-08 · Statut : acceptée
Décidé par : Antoine

## Contexte

Le 8 novembre, Antoine a fourni une nouvelle identité. Elle remplace « Palier — Référence » du 16 octobre.

## Décision

- Le signe est une courbe qui monte puis se pose en palier, avec un point à la jonction détaché par un anneau de la couleur du fond. La géométrie est la même en SVG, en SwiftUI et en Core Graphics. Les fichiers de marque sont dans `Resources/Brand/`.
- La palette **sema** devient le thème par défaut des nouveaux profils. Les six thèmes précédents restent disponibles dans Réglages → Apparence ; les choix enregistrés sont conservés.
- Le nom s'écrit « sema », toujours en minuscules, y compris en début de phrase.
- L'icône de l'app suit les fichiers d'Antoine (`sema-app-icon.svg` et sa version sombre), sans suivre le thème personnel.
- La palette et le mode Système / Clair / Sombre sont deux choix indépendants, locaux et persistants, partagés par la fenêtre, les réglages et le bandeau.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Nouvelle identité, thèmes anciens gardés | Une marque nette ; aucun profil cassé | Sept palettes à tenir |
| Remplacer les anciens thèmes | Moins de palettes | Casse les choix enregistrés |

## Conséquences

Les valeurs de couleur sont dans `Resources/Brand/tokens.json`. Les noms enregistrés des palettes ne changent jamais.
