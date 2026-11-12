# La sidebar est native, escamotable, avec un aperçu au survol

Date : 2026-10-17 · Statut : acceptée
Décidé par : Antoine

## Contexte

Après la direction Focus, Antoine a demandé une sidebar à la demande : ouverte à l'appel, jamais au survol dans la maquette. La version native a ajouté un aperçu au survol de l'icône quand la sidebar est fermée.

## Décision

- La fenêtre reste un `NavigationSplitView` natif. La sidebar réunit la recherche, les rubriques et les repères ordonnés.
- Le bouton et le raccourci système ⌃⌘S commandent sa visibilité permanente.
- Fermée, elle se révèle au survol de l'icône dans un panneau en matière native, au-dessus du graphique immobile. Elle reste ouverte sur l'icône et sur le panneau. Une tolérance de 220 ms couvre le passage de l'un à l'autre, puis elle se replie à la sortie.
- Le survol ne lance aucune requête réseau.
- « Mon espace » est fixé en bas, sous la zone défilante, et ouvre le profil local. L'accès aux réglages du hub reste là seulement : aucun engrenage ne le répète dans la barre d'outils.
- Quand la sidebar est repliée, des accès rapides apparaissent sous le graphique.
- Les transitions natives et la fermeture par Échap respectent « Réduire les animations ».
- Les textes d'action de la sidebar sont en couleur primaire. Les valeurs et compteurs utilisent un gris opaque adapté au mode clair ou sombre, pour rester lisibles sur la matière native.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Sidebar native escamotable avec aperçu | Le graphique garde sa place ; la navigation est à portée | Trois états à tenir (ouverte, fermée, aperçu) |
| Sidebar toujours ouverte | Un seul état | Moins de place pour le graphique |

## Conséquences

Trois présentations locales de sidebar sont pilotées par `WorkspaceView`. La désactivation de la scène et les feuilles ferment l'aperçu. Le fond de sélection plus présent distingue le repère actif, sans bordure.
