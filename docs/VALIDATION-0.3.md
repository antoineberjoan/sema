# Vérification du bandeau Sema 0.3

16 octobre 2026. Version locale 0.3.0, build 3, arm64, macOS 14+.

## Périmètre

Le petit panneau de barre de menus est remplacé par un bandeau de favoris, horizontal en haut/bas ou vertical à gauche/droite. Le contenu reste en SwiftUI et Swift Charts ; AppKit gère le status item et le panneau non activant. Aucun fournisseur, calcul financier ni dépendance n’est ajouté.

## Contrôles effectués

- Compilation Swift 6 en production et création du bundle ad hoc réussies, puis contrôle strict de la signature.
- Vérification dans une copie de l’app avec identifiant et dossier de données isolés, sans clé Webstat : trois favoris, puis huit favoris de démonstration. Aucune préférence de l’app principale n’est modifiée.
- Ouverture avec le menu Navigation et ⌘⇧B ; affichage sur la largeur disponible, cinq cartes visibles pour huit favoris sur l’écran testé. La flèche suivante décale la rangée d’une carte.
- Passage entre les périodes 3 mois et 1 an : variation et libellé de période mis à jour pour les cartes. Les valeurs, dates et badges Démo sont lisibles.
- Clic sur France · 10 ans : le hub s’ouvre avec la bonne série sélectionnée et sa valeur 3,42 % de démonstration.
- Échap ferme le bandeau. ⌘K depuis le bandeau ouvre la recherche native du hub.
- Sans favori, le bandeau affiche une invitation et « Choisir mes favoris » ramène au Panorama.
- L’actualisation est désactivée sans clé. Le bandeau n’ajoute aucune requête automatique.
- Identité monochrome : Graphite est sélectionné en l’absence de thème enregistré. Les six palettes restent proposées ; passage Sarcelle puis retour Graphite vérifiés dans les réglages de la copie isolée. Le logo natif, l’icône SVG et son rendu PNG sont monochromes. La compilation et la signature stricte du bundle sont valides après changement.
- Libellé obligataire précisé : « Emprunt phare FR · 10 ans », avec le sous-titre « Rendement · série mensuelle ». La clé Webstat reste `FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD`. Le nouveau titre est vérifié dans l’app relancée ; le site et le guide distinguent cette série du TEC 10 quotidien.

Le script local `./scripts/check.sh` rencontre l’absence du module Swift Testing dans les Command Line Tools installés. Les tests du cœur et la compilation du bundle sont aussi exécutés par GitHub Actions avec le SDK complet.

## Verre, placement et signature

Passe suivante du 16 octobre, dans la même copie isolée et sans clé fournisseur :

- Les quatre choix Haut, Bas, Gauche, Droite sont présents dans Apparence. Les deux dispositions natives sont observées avec huit favoris. Le choix Gauche est conservé au relancement ; les données et le thème Graphite sont préservés.
- Défilement vertical jusqu’au dernier repère et flèche suivante du carrousel horizontal vérifiés. Les cartes restent découpées dans leur zone et ne passent plus sous la signature.
- Période 3 mois : variations et mini-courbes changent, puis retour à 1 an. L’actualisation reste indisponible sans clé.
- Le signe original apparaît progressivement ; le cartouche révèle ensuite « L’économie bouge. Gardez vos repères. ». Rejouer deux fois rapidement redémarre la séquence ; ⌘K pendant la présentation ferme le bandeau et ouvre la recherche du hub. Échap est aussi contrôlé.
- La matière repose sur un `NSVisualEffectView` derrière la fenêtre ; le fond et le contenu sont frères pour éviter que la vibrance ne réduise le contraste des textes secondaires. Les captures natives isolent le panneau et ne permettent pas de juger fidèlement le bureau transmis par le flou : contrôler également à l’œil sur des fonds variés.
- Compilation en production et bundle ad hoc réussis. Le test de compatibilité des préférences conserve le nouveau champ de position lors de l’encodage/décodage et accepte les anciens documents qui en sont dépourvus.

Les comportements Réduire les animations, Réduire la transparence et Augmenter le contraste sont implémentés ; ils restent à vérifier avec les réglages système correspondants. Les réglages d’accessibilité du Mac n’ont pas été modifiés pour cette passe.

## Contrôles restant à effectuer

L’ouverture par clic sur le status item depuis une autre app, le clic extérieur, la persistance après fermeture du hub, les changements d’espace, les écrans multiples, le plein écran, VoiceOver et Réduire les animations demandent encore une vérification manuelle dédiée. Les gestionnaires correspondants sont présents, mais ne sont pas présentés ici comme validés de bout en bout. Une revue de toutes les palettes dans les deux apparences reste à faire.

Cette version reste locale pour revue. Le DMG et le cask publics 0.2.0 ne sont pas remplacés.
