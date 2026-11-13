# Le bandeau est un verre natif : cartes translucides, période du hub, quatre favoris

Date : 2026-11-08 · Statut : acceptée
Décidé par : Antoine

## Contexte

Les captures de Monocle fournies par Antoine guident la matière du bandeau. Le 8 novembre, Antoine a remplacé le rail Repère par des onglets texte dans le hub (« 3M 1A 3A 5A Max »).

## Décision

- Les cartes sont réellement translucides, avec une mince lumière sur leur bord et des coins continus. Aucun grand fond ne les encadre ; l'espace entre elles reste transparent. Chaque carte a son propre `NSVisualEffectView` (matière derrière la fenêtre).
- Le bandeau suit la période du hub, sans sélecteur propre. Les cartes font 216 points de haut ; aucune barre ne passe dessous.
- Quatre favoris au maximum se partagent la largeur disponible (minimum de 208 points par carte), avec la signature fixée hors du défilement. La signature et « Une idée ou un bug ? » restent toujours visibles.
- Le fond reste neutre en Graphite. Les autres palettes teintent légèrement le verre.
- Trois curseurs natifs dans Apparence règlent la transparence du voile, l'intensité de la teinte et un grain fin, statique et placé derrière les textes. Le libellé « Transparence » ne promet pas de changer le rayon de flou, que l'API publique ne donne pas.
- « Réduire la transparence » ou « Augmenter le contraste » impose une surface opaque.
- Aucun badge « Démo », aucune flèche décorative : la nature fictive est dite dans le détail et dans le libellé accessible.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Verre natif, réglages bornés | La matière du système, un contraste protégé | Un rendu qui dépend du bureau derrière |
| Cartes opaques | Un contraste constant | Perd la signature visuelle du bandeau |

## Conséquences

La liste des surfaces translucides et leurs exceptions est fixée par la décision `surfaces-translucides`. Le champ `ribbonGlass` des préférences porte les trois valeurs ; son absence garde le rendu précédent.
