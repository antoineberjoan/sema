# Identité de sema

## Direction

Une petite application Mac calme et précise. Mise en page et contrôles en SwiftUI natif, graphiques avec Swift Charts. Les matières, séparateurs et fonds suivent l’apparence système. Aucun kit de composants externe.

### Référence complémentaire : Resurf

Ajoutée par Antoine le 15 octobre 2026. Les vues officielles de [Resurf](https://resurf.so/) servent de référence pour une sidebar compacte, une barre d’outils discrète, des surfaces neutres légèrement chaudes et une distinction claire entre navigation, contenu et inspecteur. Pour sema, ces principes guideront les prochains ajustements de densité et de hiérarchie ; la typographie système reste retenue et les accents suivent le thème choisi dans les réglages.

### Surfaces et hiérarchie

La direction Focus, retenue le 17 octobre, donne le premier plan à la valeur et au graphique. Le détail repose sur le fond de la fenêtre, sans carte supplémentaire ni ombre intérieure. Sous le graphique, une date discrète ouvre les informations de source dans un popover natif : définition, période complète et métadonnées restent disponibles à la demande. Seule la mention courte « données fictives » accompagne la date des exemples. Aucun libellé de source ni accordéon technique ne s’ajoute à la vue principale. Les badges répétés et la seconde liste centrale sont retirés de ce parcours.

La fenêtre reste un `NavigationSplitView` natif et escamotable. Sa sidebar réunit recherche, rubriques et repères ordonnés. Les actions de navigation utilisent le texte primaire ; les valeurs et compteurs emploient un gris opaque adapté au mode clair ou sombre, pour conserver leur lisibilité sur la matière native. Un fond de sélection plus présent distingue le repère actif, sans bordure supplémentaire. « Mon espace » reste fixé en bas, sous la zone défilante ; il ouvre le profil local. Le clic sur le bouton et le raccourci système ⌃⌘S commandent sa visibilité permanente. Fermée, elle se révèle au survol de l’icône dans un panneau en matière native, au-dessus du graphique immobile. Elle reste ouverte sur l’icône et sur le panneau ; une tolérance de 220 ms couvre le passage entre eux, puis elle se replie à la sortie. Lorsque la sidebar est repliée, des accès rapides apparaissent sous le graphique. L’accès aux réglages du hub reste uniquement dans « Mon espace », au pied de la sidebar ; aucun engrenage ne le répète dans la barre d’outils. Le fond de la sidebar commence sous les boutons de fenêtre et la recherche garde 8 pt de marge haute. L’actualisation demeure disponible par ⌘R et le menu Navigation. Les transitions natives et la fermeture par Échap respectent Réduire les animations. Le survol ne lance aucune requête réseau. Le bandeau de verre conserve ses matières et ses interactions.

Le petit bouton SF Symbols `arrow.left.arrow.right` précède l’étoile uniquement sur les cartes de devises reconnues. Il partage sa zone de 26 pt, sans contour ni fond ajouté. Son aide et son libellé accessible donnent le sens cible, par exemple « Afficher EUR pour 1 USD ». Le détail propose aussi ce bouton et explicite la lecture inversée et la cotation des alertes.

### Verre et signature du bandeau

Les captures de Monocle fournies par Antoine guident la matière : des cartes macOS réellement translucides, une mince lumière sur leur bord et des coins continus. Aucun grand fond ne les encadre ; les espaces entre les cartes restent transparents. Antoine retient Repère le 17 octobre : en haut et en bas, cinq périodes restent directement visibles dans un rail SwiftUI de 84 pt tout à gauche. Un petit trait et une graisse plus présente distinguent la période active ; l’engrenage termine le rail. Chaque libellé garde une petite matière native pour sa lisibilité, sans grand encadré commun. Le rail partage les 184 pt de hauteur des cartes et s’en écarte de 12 pt ; aucune barre n’occupe le dessous. Quatre données au maximum partagent la largeur disponible, moins sur petit écran. La signature termine le défilement sans prendre une place de donnée. Le bord du panneau et le contenu gardent chacun 6 pt, soit des cartes à 12 pt de la zone visible en haut. Les positions latérales conservent leur sélecteur natif compact sous les cartes. Le fond reste neutre en Graphite ; les autres palettes teintent légèrement le verre, bleu pour Bleu polaire, vert pour Menthe ou Sarcelle, mauve pour Lavande. La matière native `underWindowBackground` reste visible derrière un voile léger, en conservant le contraste des textes. Le flou repose sur [NSVisualEffectView](https://developer.apple.com/documentation/appkit/nsvisualeffectview), en mode derrière la fenêtre, sans dépendance externe ni imitation d’un fond d’écran. Le voile de contraste laisse passer la matière et protège la lecture des chiffres. Trois curseurs natifs dans Apparence règlent la transparence du voile, l’intensité de la teinte de la palette et un grain fin, statique et placé derrière les textes. Le libellé Transparence ne promet pas de modifier le rayon du flou natif, non exposé par l’API publique. Graphite garde sa teinte neutre. L’aperçu reprend une vraie carte favorite et la remise à zéro ne change ni palette ni mode. Réduire la transparence ou Augmenter le contraste impose une surface opaque.

Le cartouche dit **« L’économie bouge. Gardez vos repères. »**. Le tracé Palier commence après 300 ms et dure 1 800 ms ; le contexte apparaît à 1 250 ms, puis la signature à 1 850 ms, avec des fondus de 800 ms. Ces valeurs sont centralisées dans `SignatureMotion`. Une séquence à chaque présentation, aucune boucle ni bouton Rejouer. Le nom n’est pas répété au-dessus du signe ; 18 pt séparent la mission du bouton de retour. Réduire les animations affiche directement le résultat. Les données restent accessibles pendant toute la séquence. Ce cartouche est intégré au bandeau natif. Son fond bleu ardoise (`#355A80`) constitue l’unique surface éditoriale colorée en Graphite ; les thèmes personnels réemploient leur accent approfondi. Un fond noir sous le dégradé et des textes blancs préservent le contraste. Le bouton « Une idée ou un bug ? » ouvre le formulaire Notion public, sans accès aux réponses. La marque et l’icône restent monochromes.

## Typographie

**SF Pro**, via `.system` : aucune police à télécharger ou embarquer. Conserver les styles natifs des contrôles ; utiliser `monospacedDigit()` pour aligner les valeurs financières. Les titres emploient les graisses medium et semibold. Éviter d’ajouter une seconde famille typographique.

## Rythme et rayons

Deux unités d’espacement, selon le principe d’Interface Craft repris de Josh Puckett : 8 pt entre éléments liés, 24 pt entre groupes. Un rayon par rôle : 12 pt pour les lignes et tuiles sélectionnables, 16 pt pour les cartes dans une vue, 22 pt pour les surfaces et panneaux flottants. Une sélection prend une teinte à 12 %, accent ou neutre dans la sidebar ; un survol, un voile neutre à 4 %. Valeurs posées le 17 octobre 2026, à valider à l’œil dans l’app.

## Couleurs

Graphite est le thème par défaut : noir, blanc et gris. Six thèmes restent disponibles dans **Réglages → Apparence** ; les choix enregistrés sont conservés. Sarcelle, Menthe, Lavande, Bleu ciel et Bleu polaire sont des personnalisations facultatives.

| Thème | Palette de référence |
| --- | --- |
| Menthe | `#8EC3B0` · `#9ED5C5` · `#BCEAD5` · `#DEF5E5` |
| Lavande | `#D0A2F7` · `#DCBFFF` · `#E5D4FF` · `#F1EAFF` |
| Bleu ciel | `#00A9FF` · `#89CFF3` · `#A0E9FF` · `#CDF5FD` |
| Sarcelle | `#265073` · `#2D9596` · `#9AD0C2` · `#ECF4D6` |
| Bleu polaire | `#053F56` · `#21A5EC` · `#90D2F5` · `#F2F3F7` |
| Graphite | `#333333` · `#707070` · `#D6D6D6` · `#FAFAFA` |

Les références pastel sont conservées dans l’aperçu. Les accents sont approfondis sur fond clair pour les textes, les courbes et les contrôles sélectionnés, puis éclaircis pour les courbes en mode sombre. Surfaces et typographie restent sémantiques macOS. La palette et le mode d’affichage Système / Clair / Sombre sont deux choix indépendants, locaux et persistants, partagés par la fenêtre, les réglages et le bandeau. Le mode Système suit les changements de macOS ; Clair et Sombre ne modifient pas l’apparence des autres apps. La marque, le site, la page de téléchargement et l’icône d’app sont monochromes. L’icône présente le signe blanc sur un fond graphite, indépendamment du thème personnel.

## Symbole — Palier · Référence

Retenu le 16 octobre 2026. Le dessin « Palier — Référence » d’Antoine remplace Déploiement D3 · Apaisé. La courbe du SVG fourni est conservée exactement : une boucle élancée, un passage et une sortie en palier. Seuls le centrage uniforme et les épaisseurs optiques changent selon le support. Le signe évoque un repère sans représenter une donnée réelle.

La géométrie est identique en SVG, SwiftUI et Core Graphics. Trois poids optiques dans le kit : Display (trait source 3,6, à partir de 96 px), Standard (6, de 28 à 95 px), Compact (8,5, de 16 à 27 px). Le symbole ne descend pas sous 16 px. L’icône d’app utilise le poids Compact dans un carré encre aux coins arrondis, avec un signe blanc.

- `Resources/Brand/sema-symbol.svg` : Standard, transparent.
- `Resources/Brand/sema-symbol-mono.svg` : variante renforcée pour la barre de menus, trait source 20,915033 (2 pt à 18 pt). Le poids Compact général reste inchangé.
- `Resources/Brand/sema-icon.svg` : icône de l’app.
- `SemaSymbol` : géométrie native, poids adapté à la taille.
- `scripts/render-icon.swift` : PNG et icône du bundle.

## Marque et rédaction

Le nom s’écrit **sema**, toujours en minuscules, y compris en début de phrase et dans le mot-symbole. Les noms techniques des cibles Swift, des fichiers distribués et du dossier de stockage existant restent stables.

Signature : **Gardez vos repères.** La promesse est de réunir les repères économiques du conseiller dans une petite app Mac. Trois qualités guident les choix : calme, précision, attention aux détails. Le ton est direct, posé et concret ; vouvoiement, phrases courtes, vocabulaire financier explicité. Toujours afficher source, période et unité. Une hausse de taux n’est pas automatiquement une bonne nouvelle : garder une couleur neutre et une variation signée.

Le guide de marque v1.3 et ses démonstrations de mouvement sont accessibles dans le site privé, à `/brand/`. Le kit de livraison comprend les SVG, les tokens JSON/CSS et le guide HTML autonome. Les démonstrations du guide ne changent pas le fonctionnement de l’app. Les animations actuelles restent natives, avec Réduire les animations respecté ; toute nouvelle séquence se valide au clavier, à vitesse normale et en interruption rapide.

### Présentation web — retenue du 17 octobre

L’accueil se limite à une promesse en deux lignes, un téléchargement, un lien Homebrew discret, une capture et trois réponses utiles. La ligne secondaire dit « l’historique pour comprendre. les alertes pour agir. » ; la note Ko-fi revient sous les questions. Les recherches simulées, agrandissements et libellés décoratifs ont été retirés. Les textes visibles de l’accueil sont en minuscules.

L’accueil et la page d’installation partagent un header fixe au défilement : le signe Palier à gauche, sans lien « nouveautés ». « télécharger » apparaît uniquement après la sortie du bouton principal au-dessus de la zone visible ; il disparaît au retour. Il reprend sa destination depuis le bouton principal, y compris le fichier distribué sur la page d’installation. Masqué, le lien est inerte et absent du parcours clavier. Le footer tient sur une ligne sur grand écran, avec l’auteur, les retours, les mentions légales et la confidentialité, en minuscules et sans encadré. Le soutien Ko-fi reste dans une note discrète avant le footer. Les deux pages légales sont publiées à la demande d’Antoine avec son e-mail public, sans téléphone personnel ; les informations restant à régulariser sont consignées dans `LEGAL.md`. La commande Homebrew complète reste dans les instructions d’installation ; l’accueil affiche uniquement « installer avec homebrew ». La capture du hub Focus provient du bundle natif de revue 0.5.0, en Graphite sombre, avec les valeurs fictives identifiées. Son masque proportionnel suit les coins de la fenêtre, sans modifier les pixels du fichier source.

Le signe se trace une seule fois à chaque chargement, après 160 ms et pendant 2 400 ms. Aucune répétition au défilement. Réduire les animations affiche immédiatement le signe complet et supprime la transition du bouton. Ces durées sont des choix sema réglables dans les variables de `site/dist/chrome.css`, selon les principes d’Interface Craft.
