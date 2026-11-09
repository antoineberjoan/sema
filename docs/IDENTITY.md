# Identité de sema

## Direction

Une petite application Mac calme et précise. Mise en page et contrôles en SwiftUI natif, graphiques avec Swift Charts. Les matières, séparateurs et fonds suivent l’apparence système. Aucun kit de composants externe.

### Référence complémentaire : Resurf

Ajoutée par Antoine le 15 octobre 2026. Les vues officielles de [Resurf](https://resurf.so/) servent de référence pour une sidebar compacte, une barre d’outils discrète, des surfaces neutres légèrement chaudes et une distinction claire entre navigation, contenu et inspecteur. Pour sema, ces principes guideront les prochains ajustements de densité et de hiérarchie ; la typographie système reste retenue et les accents suivent le thème choisi dans les réglages.

### Surfaces et hiérarchie

La direction Focus, retenue le 17 octobre, donne le premier plan à la valeur et au graphique. Le détail repose sur le fond de la fenêtre, sans carte supplémentaire ni ombre intérieure. La variation et son horizon figurent dans un petit badge à côté de la valeur, avec la couleur du thème et sans code vert/rouge. Le bouton « Créer une alerte » se place juste sous le badge, sur le même alignement gauche ; ce bloc est centré verticalement à côté de la valeur et se replie dessous si la largeur manque. La barre supérieure conserve le bouton de sidebar sans répéter le nom sema. Sous le graphique, « Donnée du… » (ou la période complète) précise la date de la valeur publiée, sous forme de texte sans interaction. Antoine demande ensuite la suppression du grand panneau de source : aucun popover, aucune aide au survol ni panneau de remplacement ne part de cette date. Définition, métadonnées et date d’actualisation restent dans les aperçus du catalogue. Les paires de devises vérifiées utilisent un titre court français (« Euro / Dollar ») et leur code de devise (« USD ») dans les vues de consultation et de navigation. Le libellé officiel et l’unité complète restent dans les informations de source ; les autres séries conservent leur libellé. L’alerte utilise un petit bouton natif secondaire en capsule, cohérent avec le badge, sans répétition au pied du graphique ; son état indisponible conserve les règles de source et d’unité. Seule la mention courte « données fictives » accompagne la date des exemples. Aucun libellé de source ni accordéon technique ne s’ajoute à la vue principale. Les badges répétés et la seconde liste centrale sont retirés de ce parcours.

La fenêtre reste un `NavigationSplitView` natif et escamotable. Sa sidebar réunit recherche, rubriques et repères ordonnés. Les actions de navigation utilisent le texte primaire ; les valeurs et compteurs emploient un gris opaque adapté au mode clair ou sombre, pour conserver leur lisibilité sur la matière native. Un fond de sélection plus présent distingue le repère actif, sans bordure supplémentaire. « Mon espace » reste fixé en bas, sous la zone défilante ; il ouvre le profil local. Le clic sur le bouton et le raccourci système ⌃⌘S commandent sa visibilité permanente. Fermée, elle se révèle au survol de l’icône dans un panneau en matière native, au-dessus du graphique immobile. Elle reste ouverte sur l’icône et sur le panneau ; une tolérance de 220 ms couvre le passage entre eux, puis elle se replie à la sortie. Lorsque la sidebar est repliée, des accès rapides apparaissent sous le graphique. L’accès aux réglages du hub reste uniquement dans « Mon espace », au pied de la sidebar ; aucun engrenage ne le répète dans la barre d’outils. Le fond de la sidebar commence sous les boutons de fenêtre et la recherche garde 8 pt de marge haute. L’actualisation demeure disponible par ⌘R et le menu Navigation. Les transitions natives et la fermeture par Échap respectent Réduire les animations. Le survol ne lance aucune requête réseau. Le bandeau de verre conserve ses matières et ses interactions.

Le petit bouton SF Symbols `arrow.left.arrow.right` précède l’étoile uniquement sur les cartes de devises reconnues. Il partage sa zone de 26 pt, sans contour ni fond ajouté. Son aide et son libellé accessible donnent le sens cible, par exemple « Afficher EUR pour 1 USD ». Le détail propose aussi ce bouton et explicite la lecture inversée et la cotation des alertes.

### Explorer

Précision d’Antoine du 17 octobre : intuitif et simple, sans phrases de remplissage. L’entrée montre les sources actives et leur domaine, sans requête globale ni écran Webstat imposé. Une source ouvre sa recherche et ses résultats ; le bouton Sources permet de revenir au choix. La recherche et son effacement sont communs à Explorer et aux catalogues de ⌘K. Chaque jeu ouvre la liste des séries déjà publiées, recherchables par leur nom, avant l’aperçu et l’ajout. Les dimensions, la description longue et le code exact restent facultatifs dans Recherche avancée ; aucune combinaison n’est imposée ni créée silencieusement. Les erreurs gardent leur reprise locale. Aucun pied de page permanent ni deuxième connexion Webstat dans Explorer.

### Verre et signature du bandeau

Les captures de Monocle fournies par Antoine guident la matière : des cartes macOS réellement translucides, une mince lumière sur leur bord et des coins continus. Aucun grand fond ne les encadre ; les espaces entre les cartes restent transparents. Le 8 novembre, Antoine remplace le rail Repère par des onglets texte dans le hub (« 3M 1A 3A 5A Max ») : le bandeau suit la période du hub, sans sélecteur propre, et garde l’accès aux réglages sur sa signature. Les cartes gardent 216 pt de haut ; aucune barre n’occupe le dessous. Quatre favoris au maximum partagent la largeur disponible, en plus du cartouche signature fixé hors du défilement ; moins de favoris sont visibles sur petit écran. La signature et « Une idée ou un bug ? » restent toujours visibles, y compris sans favori. La capacité se calcule avec une largeur minimale de 208 pt ; les cartes et la signature se partagent ensuite toute la largeur disponible, sans plafond individuel, pour 216 pt de haut. Ce comportement suit la demande d’Antoine du 18 octobre ; [contrat et preuves](plans/keyboard-navigation.md). Aucun badge « Démo » ni flèche décorative ne figure dans les cartes ; la nature fictive reste indiquée dans le détail et dans leur libellé accessible. Le bord du panneau et le contenu gardent chacun 6 pt, soit des cartes à 12 pt de la zone visible en haut. Les positions latérales conservent leur sélecteur natif compact sous les cartes. Le fond reste neutre en Graphite ; les autres palettes teintent légèrement le verre, bleu pour Bleu polaire, vert pour Menthe ou Sarcelle, mauve pour Lavande. La matière native `underWindowBackground` reste visible derrière un voile léger, en conservant le contraste des textes. Le flou repose sur [NSVisualEffectView](https://developer.apple.com/documentation/appkit/nsvisualeffectview), en mode derrière la fenêtre, sans dépendance externe ni imitation d’un fond d’écran. Le voile de contraste laisse passer la matière et protège la lecture des chiffres. Trois curseurs natifs dans Apparence règlent la transparence du voile, l’intensité de la teinte de la palette et un grain fin, statique et placé derrière les textes. Le libellé Transparence ne promet pas de modifier le rayon du flou natif, non exposé par l’API publique. Graphite garde sa teinte neutre. L’aperçu reprend une vraie carte favorite et la remise à zéro ne change ni palette ni mode. Réduire la transparence ou Augmenter le contraste impose une surface opaque.

Le cartouche dit **« L’économie bouge. Gardez vos repères. »**. Le tracé du repère dure 550 ms (`Motion.explain`), puis le contexte et la mission apparaissent en 200 ms, décalés de 50 ms : la séquence reste sous 900 ms, selon Mouvement 1.1. Ces valeurs sont centralisées dans `SignatureMotion`, à partir des jetons `Motion`. Une séquence à chaque présentation, aucune boucle ni bouton Rejouer. Le nom n’est pas répété au-dessus du signe ; 18 pt séparent la mission du bouton de retour. Réduire les animations affiche directement le résultat. Les données restent accessibles pendant toute la séquence. Ce cartouche est intégré au bandeau natif. Son fond reprend toujours l’accent approfondi du thème choisi dans Apparence, y compris le gris neutre de Graphite. Un fond noir sous le dégradé et des textes blancs préservent le contraste. Le bouton « Une idée ou un bug ? » ouvre le formulaire Notion public, sans accès aux réponses. La marque garde l’encre et le papier ; seul le point du repère prend la Sarcelle Profonde.

## Typographie

Spécification *Typographie 1.1* d’Antoine du 5 novembre, appliquée le 8 novembre. **SF Pro** via la police système, sans police embarquée. Les tailles vivent uniquement dans `TypeRole`, appliqué avec `.typeRole(_:)` : hero 44, title 28, figure 24, section 19, subheading 16, heading 15, body 15 (interligne 26,25), lede 17, label 14, small et caption 13, overline et tag 12, micro 11,52, wordmark 17. Le garde-fou refuse une taille écrite en chiffres ailleurs. `monospacedDigit()` aligne les valeurs financières.

## Espace, forme et mouvement

Spécifications *Espace et forme 1.1* et *Mouvement 1.1* du 5 novembre, appliquées le 8 novembre ; elles remplacent les rythmes (8/24) et rayons (12/16/22) du 17 octobre.

- `Spacing` : 2, 4, 6, 8, 10, 12, 14, 16, 24, 32, 48 et 64 pt. Rangées et groupes liés en 8 à 16, groupes en 24, page en 32.
- `Radius` : marque 4, contrôle 6, bloc 10, fenêtre 14, carte 16.
- Élévations 0 à 3 dans `Theme`, filet de 1 pt.
- `Motion` : instantané 0, pression 120 ms, rapide 150 ms, standard 200 ms, large 300 ms, explication 550 ms ; sortie à 60 % de l’entrée, échelle de départ 0,96, pression 0,97, décalage 4 pt, cascade 50 ms. Réduire les animations garde les fondus et retire les déplacements.

## Couleurs

Identité fournie par Antoine le 8 novembre : la palette **sema** devient le thème par défaut des nouveaux profils. Encre `#141414`, Graphite `#474747`, Papier `#FAFAFA`, Brume `#E3E5E2` et Sarcelle Profonde `#1F6F73` (accent clair ; `#7CC2C0` en sombre). L’écart à l’habituel d’un mouvement se lit en cinq zones d’intensité de la sarcelle (`MoveBadge`). Les six thèmes précédents restent disponibles dans **Réglages → Apparence** ; les choix enregistrés sont conservés.

| Thème | Palette de référence |
| --- | --- |
| Menthe | `#8EC3B0` · `#9ED5C5` · `#BCEAD5` · `#DEF5E5` |
| Lavande | `#D0A2F7` · `#DCBFFF` · `#E5D4FF` · `#F1EAFF` |
| Bleu ciel | `#00A9FF` · `#89CFF3` · `#A0E9FF` · `#CDF5FD` |
| Sarcelle | `#265073` · `#2D9596` · `#9AD0C2` · `#ECF4D6` |
| Bleu polaire | `#053F56` · `#21A5EC` · `#90D2F5` · `#F2F3F7` |
| sema | `#141414` · `#1F6F73` · `#E3E5E2` · `#FAFAFA` |
| Graphite | `#333333` · `#707070` · `#D6D6D6` · `#FAFAFA` |

Les références pastel sont conservées dans l’aperçu. Les accents sont approfondis sur fond clair pour les textes, les courbes et les contrôles sélectionnés, puis éclaircis pour les courbes en mode sombre. Surfaces et typographie restent sémantiques macOS. La palette et le mode d’affichage Système / Clair / Sombre sont deux choix indépendants, locaux et persistants, partagés par la fenêtre, les réglages et le bandeau. Le mode Système suit les changements de macOS ; Clair et Sombre ne modifient pas l’apparence des autres apps. L’icône d’app suit les fichiers d’Antoine (`sema-app-icon.svg` et sa version sombre), indépendamment du thème personnel. Le site garde son identité actuelle jusqu’à son propre chantier.

## Symbole — repère

Identité fournie par Antoine le 8 novembre ; elle remplace « Palier — Référence » du 16 octobre. Une courbe qui monte puis se pose en palier (`M120 368 C210 368 232 214 312 214 H392`, trait 36 sur un carré de 512), et un point sarcelle à la jonction (rayon 34), détaché par un anneau de la couleur du fond (trait 14).

La géométrie est identique en SVG, SwiftUI et Core Graphics.

- `Resources/Brand/` : logo, lockup, icônes claire et sombre, couleurs JSON.
- `SignalPath` : courbe dans un carré de 320 ; `SignalDot` : point et anneau ; `Symbol` les assemble.
- `scripts/render-icon.swift` : PNG et icône du bundle d’après `sema-app-icon.svg`.

## Marque et rédaction

Le nom s’écrit **sema**, toujours en minuscules, y compris en début de phrase et dans le mot-symbole. Les noms techniques des cibles Swift, des fichiers distribués et du dossier de stockage existant restent stables.

Signature : **Gardez vos repères.** La promesse est de réunir les repères économiques du conseiller dans une petite app Mac. Trois qualités guident les choix : calme, précision, attention aux détails. Le ton est direct, posé et concret ; vouvoiement, phrases courtes, vocabulaire financier explicité. Toujours afficher source, période et unité. Une hausse de taux n’est pas automatiquement une bonne nouvelle : garder une couleur neutre et une variation signée.

Le guide de marque v1.3, volontairement minimal (marque, signe, couleur, typographie, voix, kit), est accessible sans lien public à `/brand/`. Il sert de kit de livraison : SVG, tokens JSON/CSS et guide HTML autonome. Les décisions et leur explication vivent dans Notion ; l’interface et le mouvement se jugent dans l’app. Les animations actuelles restent natives, avec Réduire les animations respecté ; toute nouvelle séquence se valide au clavier, à vitesse normale et en interruption rapide.

### Présentation web — retenue du 17 octobre

L’accueil se limite à une promesse en deux lignes, un téléchargement, un lien Homebrew discret, une capture et trois réponses utiles. La ligne secondaire dit « l’historique pour comprendre. les alertes pour agir. » ; la note Ko-fi revient sous les questions. Les recherches simulées, agrandissements et libellés décoratifs ont été retirés. Les textes visibles de l’accueil sont en minuscules.

L’accueil et la page d’installation partagent un header fixe au défilement : le signe Palier à gauche, sans lien « nouveautés ». « télécharger » apparaît uniquement après la sortie du bouton principal au-dessus de la zone visible ; il disparaît au retour. Il reprend sa destination depuis le bouton principal, y compris le fichier distribué sur la page d’installation. Masqué, le lien est inerte et absent du parcours clavier. Le footer tient sur une ligne sur grand écran, avec l’auteur, les retours, les mentions légales et la confidentialité, en minuscules et sans encadré. Le soutien Ko-fi reste dans une note discrète avant le footer. Les deux pages légales sont publiées à la demande d’Antoine avec son e-mail public, sans téléphone personnel ; les informations restant à régulariser sont consignées dans `LEGAL.md`. La commande Homebrew complète reste dans les instructions d’installation ; l’accueil affiche uniquement « installer avec homebrew ». La capture du hub Focus provient du bundle natif de revue 0.5.0, en Graphite sombre, avec les valeurs fictives identifiées. Son masque proportionnel suit les coins de la fenêtre, sans modifier les pixels du fichier source.

Le signe se trace une seule fois à chaque chargement, après 160 ms et pendant 2 400 ms. Aucune répétition au défilement. Réduire les animations affiche immédiatement le signe complet et supprime la transition du bouton. Ces durées sont des choix sema réglables dans les variables de `site/dist/chrome.css`, selon les principes d’Interface Craft.
