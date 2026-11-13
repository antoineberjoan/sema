# La valeur et le graphique passent d'abord, sans carte ni ombre autour du détail

Date : 2026-10-17 · Statut : acceptée
Décidé par : Antoine

## Contexte

Cinq maquettes de composition ont été comparées le 17 octobre : Atelier, Focus, Journal, Feuille et Horizon (cartes en verre sur le bureau). Focus et Horizon ont été retenues, Horizon devenant le bandeau de verre. Atelier, Journal et Feuille n'ont pas été retenues ; aucune raison n'est écrite. Le détail d'une série devait montrer l'essentiel sans bruit. Le 15 octobre, Antoine avait déjà ajouté Resurf comme référence : sidebar compacte, barre d'outils discrète, surfaces neutres, navigation, contenu et inspecteur bien distincts.

## Décision

La direction **Focus** est retenue.

- Le détail repose sur le fond de la fenêtre, sans carte en plus et sans ombre intérieure.
- La variation et son horizon sont dans un petit badge à côté de la valeur. Il prend la couleur du thème, sans code vert ou rouge : une hausse de taux n'est pas toujours une bonne nouvelle.
- Le bouton d'alerte est juste sous le badge, sur le même alignement. Ce bloc se replie sous la valeur si la largeur manque.
- Sous le graphique, la date de la valeur publiée est un texte sans interaction. Antoine a demandé de retirer le grand panneau de source : aucun popover, aucune aide au survol ne part de cette date. Définition, métadonnées et date d'actualisation restent dans les aperçus du catalogue.
- Les paires de devises vérifiées ont un titre court français (« Euro / Dollar ») et leur code (« USD »). Le libellé officiel reste dans les informations de source.
- Seule la mention « données fictives » accompagne la date des exemples. Aucun libellé de source ni accordéon technique dans la vue principale.
- Resurf reste une référence de densité et de hiérarchie. La typographie reste celle du système et l'accent suit le thème choisi.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Focus : un plan, la valeur d'abord | Une lecture calme, peu de surfaces | Moins de place pour les informations de source |
| Cartes et panneaux autour du détail | Chaque information a son cadre | Des surfaces imbriquées, plus de bruit |

## Conséquences

Les informations de source passent en second niveau. Le badge et le bouton d'alerte forment un bloc qui se replie. Le mot « Focus » désigne encore le mode de détail dans le code.
