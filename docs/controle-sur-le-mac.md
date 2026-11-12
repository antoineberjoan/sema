# À vérifier sur le Mac, écran par écran

Ce fichier liste ce que ni un outil ni une relecture ne peuvent établir sans écran. Chaque ligne dit quoi regarder, où, et par rapport à quel rôle de Sophos. Condition de sortie de chaque ligne : la personne qui regarde la coche, ou ouvre une décision si le rendu ne convient pas.

Avant tout : `swift build` réussit, `swift test --disable-xctest` passe, et l'app s'ouvre. Regarder ensuite en clair et en sombre, avec « Augmenter le contraste » et « Réduire la transparence » activés une fois.

## Favoris

- L'écart entre le nom et la valeur d'une tuile (`title-gap`, 4 points) : la tuile reste lisible. C'est le plus fort changement de l'écran (16 → 4 points).
- Les boutons au coin d'une carte (`row-inset`) ne se chevauchent pas avec le titre, avec un ou deux boutons (`icon.button-size`).

## Accueil

- Les tuiles de thème (rayon `block`), la tuile choisie (fond `selection`, contour `border.width`, coche) : l'état choisi se voit sans le contour de 1,5 point d'avant.
- Les points de progression (`icon.gap`, point inactif `rule-hover`) : le point actif se distingue.
- Les icônes de section en `accent-text` : contraste lisible en clair et en sombre.

## Aperçu

- Nom, valeur et variation (`title-gap`) : la hiérarchie du bloc se lit.
- Marges de l'inspecteur (`page-inset-narrow`) et du sélecteur Focus (`page-inset-wide`).
- Le badge de variation (`accent-text` sur `selection`) et le sélecteur Focus (texte secondaire système, matière translucide).
- Les onglets de période et les deux boutons d'icône au clavier : ordre de Tab, focus visible (`focus`).

## Alertes

- La feuille de création (`page-inset-narrow`, champs séparés par `field-gap`).
- L'encadré « Surveiller vos favoris ? » (`surface`, rayon `block`) : il reste visible sur la fenêtre opaque.
- La cloche et « Surveillé » en `accent-text`.

## Brief

- Les blocs séparés de 48 points (`section-gap`) : la page respire sans paraître vide.
- Les lignes de mouvement (`row-inset`) et le texte discret (`text-muted`, deux gris devenus un) : la variation et le rang restent lisibles.
- La carte Agenda (`card-inset`, fond `surface`) et le jour choisi (`selection`) sur `surface-raised`.

## Explorateur

- Les lignes de résultat (`row-inset`, `list-gap-dense`) et leur sélection (`selection`) : la sélection se voit en clair et en sombre.
- Les champs de recherche à 12 points contre les lignes à 8 points : l'écart de 4 points à l'alignement.
- Le champ de clé exacte (rôle `code`) et le panneau de recherche rapide (matière translucide, texte secondaire système).
- Les feuilles et zones de chargement (`page-inset-narrow`).

## Bandeau

- L'écart de 12 points entre cartes (`field-gap`) : le nombre de cartes visibles ne change pas sur un petit écran.
- Le verre des cartes (`RibbonSurface`) avec « Réduire la transparence » : repli opaque. Le voile, le reflet et le bord lisent des rôles de couleur (papier et encre au lieu d'un blanc et d'un noir purs) : la différence de teinte est minime, à confirmer à l'œil, en clair et en sombre.
- **La signature** : le texte, le tracé et le bord lisent `on-accent` sur un dégradé d'accent. À mesurer à l'œil aux deux extrémités du dégradé, en clair et en sombre : la mesure de contraste de Sophos ne couvre pas un dégradé. En mode sombre, `on-accent` est une encre foncée : vérifier qu'elle reste lisible sur le fond noir sous le dégradé.
- **L'icône de la barre des menus** : l'image est un modèle, rendu avec `DesignColor.text` (une couleur adaptative, jamais écrite dans le code). Vérifier qu'elle reste nette en clair et en sombre, et sur un fond de bureau coloré.
- Le mouvement de la signature (tracé 550 ms, apparition du texte) : fluide, et immédiatement à l'état final avec « Réduire les animations ».

## Réglages

- Le repère « Mon espace » (`selection`, teinte d'accent à la place d'un gris neutre) : même rendu dans toutes les barres latérales.
- Les tuiles de choix (`surface-raised`, `surface`) et les interrupteurs (`accent-control`).
- La recherche d'un réglage au clavier : Tab, Échap, Entrée.

## Espace de travail

- La sélection de la barre latérale en teinte d'accent, un seul chemin pour la barre ouverte et l'aperçu.
- **Le voile derrière le sélecteur Focus (`scrim`, 32 % en clair, 56 % en sombre)** : beaucoup plus marqué que l'ancien noir à 3,5 %. Si c'est trop fort, reprendre le rôle avec Sophos.
- Les marges (`page-inset-narrow`, `page-inset-wide`) et l'ombre du panneau d'aperçu (`floating`).

## Recherche

- Le panneau de recherche rapide : matière translucide, texte secondaire système, focus au clavier dès l'ouverture.

## Premier lancement

- Le parcours complet au clavier seul, avec VoiceOver : chaque tuile annonce « Choisi » ou « Non choisi ».

## Transversal

- Textes de l'interface : phrases courtes, un terme stable par chose (relu contre `expliquer` : le texte de l'attribution de la Fed de New York est un texte légal imposé par le service, en anglais, et n'est pas réécrit).
- `isEnabled`, `isSelected`, `isFocus`, `isOpaque` dans les vues : aucune ambiguïté de nom avec SwiftUI à la compilation.
