# Cinq directions pour sema

Maquettes de composition demandées le 17 octobre 2026. Aucun changement de l’interface SwiftUI n’est appliqué à ce stade.

Ouvrir `app-directions.html` dans un navigateur : le fichier est autonome, sans dépendance, sans connexion réseau et sans API. Les cinq boutons changent de composition ; Clair / Sombre change l’apparence. Dans Focus, le bouton de sidebar ouvre et replie les repères ; leur sélection met à jour la valeur, l’unité, la courbe, les graduations et la source fictives. Échap replie la sidebar et replace le focus sur son bouton. Les autres contrôles dessinés restent des intentions de maquette, notamment les réglages, les périodes et les alertes ; ils ne pilotent pas l’app native.

| Direction | Composition | Intérêt |
| --- | --- | --- |
| Atelier | Sidebar discrète et graphique dominant ; les autres repères restent en pied | Navigation familière pour un usage quotidien |
| Focus | Une seule surface, un grand historique et une sidebar escamotable ; accès rapides en bas lorsqu’elle est repliée | Consultation d’un repère sans distraction |
| Journal | Hiérarchie éditoriale, une série principale et trois observations secondaires | Lecture globale, calme et peu technique |
| Feuille | Table alignée, valeurs, variations, historiques et dates | Comparer plusieurs séries sans cartes |
| Horizon | Cartes en verre sur le bureau, périodes dans une colonne compacte | Accès rapide depuis la barre de menus |

Toutes les valeurs et courbes sont fictives. La mention est unique, en dehors de la maquette, pour éviter les badges répétés. Dans l’application réelle, l’origine fictive doit rester identifiable ; une suppression de bruit ne doit pas faire passer une simulation pour une publication officielle.

Principes communs : Graphite, typographie système, une action principale, absence de boutons « Détails », pas de cartes imbriquées, sources et dates en second niveau, accès aux réglages discret. Aucun mouvement décoratif. Les proportions et les matières sont des intentions à traduire ensuite en SwiftUI / AppKit, pas la preuve d’un rendu natif déjà réalisé.

Vérifications : les cinq compositions ont été vues dans le navigateur ; le changement de composition fonctionne au clavier ; le mode sombre a été contrôlé sur Journal et Horizon. Aucun test fonctionnel Swift n’est requis pour ces maquettes indépendantes.

Le 17 octobre, Focus est prolongé avec une sidebar à la demande, selon le retour d’Antoine. Ouverture explicite, sans déclenchement au survol ; transition de largeur de 240 ms, supprimée avec Réduire les animations. La navigation en bas est masquée et retirée du parcours clavier lorsque la sidebar est ouverte, pour éviter la répétition. Le bouton Réglages reste placé en haut à droite. Cette évolution est une proposition interactive, pas une refonte SwiftUI déjà livrée.

Vérification du prototype Focus : ouverture et fermeture au clavier avec retour de focus, sélection de l’emprunt phare avec mise à jour des graduations et de la source, retour Euro / Dollar, apparences claire et sombre. Aucune erreur de console observée. Le mode sans mouvement est prévu par la media query système ; son activation n’a pas été simulée dans le navigateur.
