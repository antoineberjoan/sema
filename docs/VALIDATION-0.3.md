# Vérification du bandeau Sema 0.3

16 octobre 2026. Version locale 0.3.0, build 3, arm64, macOS 14+.

## Périmètre

Le petit panneau de barre de menus est remplacé par un bandeau horizontal sous la barre des menus. Le contenu reste en SwiftUI et Swift Charts ; AppKit gère le status item et le panneau non activant. Aucun fournisseur, calcul financier ni dépendance n’est ajouté.

## Contrôles effectués

- Compilation Swift 6 en production et création du bundle ad hoc réussies, puis contrôle strict de la signature.
- Vérification dans une copie de l’app avec identifiant et dossier de données isolés, sans clé Webstat : trois favoris, puis huit favoris de démonstration. Aucune préférence de l’app principale n’est modifiée.
- Ouverture avec le menu Navigation et ⌘⇧B ; affichage sur la largeur disponible, cinq cartes visibles pour huit favoris sur l’écran testé. La flèche suivante décale la rangée d’une carte.
- Passage entre les périodes 3 mois et 1 an : variation et libellé de période mis à jour pour les cartes. Les valeurs, dates et badges Démo sont lisibles.
- Clic sur France · 10 ans : le hub s’ouvre avec la bonne série sélectionnée et sa valeur 3,42 % de démonstration.
- Échap ferme le bandeau. ⌘K depuis le bandeau ouvre la recherche native du hub.
- Sans favori, le bandeau affiche une invitation et « Choisir mes favoris » ramène au Panorama.
- L’actualisation est désactivée sans clé. Le bandeau n’ajoute aucune requête automatique.

Le script local `./scripts/check.sh` rencontre l’absence du module Swift Testing dans les Command Line Tools installés. Les tests du cœur et la compilation du bundle sont aussi exécutés par GitHub Actions avec le SDK complet.

## Contrôles restant à effectuer

L’ouverture par clic sur le status item depuis une autre app, le clic extérieur, la persistance après fermeture du hub, les changements d’espace, les écrans multiples, le plein écran, VoiceOver et Réduire les animations demandent encore une vérification manuelle dédiée. Les gestionnaires correspondants sont présents, mais ne sont pas présentés ici comme validés de bout en bout. Une revue de toutes les palettes dans les deux apparences reste à faire.

Cette version reste locale pour revue. Le DMG et le cask publics 0.2.0 ne sont pas remplacés.
