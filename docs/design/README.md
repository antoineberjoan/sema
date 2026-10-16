# Cinq directions pour sema

Maquettes de composition demandées le 17 octobre 2026. Aucun changement de l’interface SwiftUI n’est appliqué à ce stade.

Ouvrir `app-directions.html` dans un navigateur : le fichier est autonome, sans dépendance, sans connexion réseau et sans API. Les cinq boutons changent de composition ; Clair / Sombre change l’apparence. Les contrôles dessinés à l’intérieur des fenêtres sont des éléments de maquette, pas des fonctionnalités implémentées.

| Direction | Composition | Intérêt |
| --- | --- | --- |
| Atelier | Sidebar discrète et graphique dominant ; les autres repères restent en pied | Navigation familière pour un usage quotidien |
| Focus | Une seule surface, un grand historique et une navigation en bas | Consultation d’un repère sans distraction |
| Journal | Hiérarchie éditoriale, une série principale et trois observations secondaires | Lecture globale, calme et peu technique |
| Feuille | Table alignée, valeurs, variations, historiques et dates | Comparer plusieurs séries sans cartes |
| Horizon | Cartes en verre sur le bureau, périodes dans une colonne compacte | Accès rapide depuis la barre de menus |

Toutes les valeurs et courbes sont fictives. La mention est unique, en dehors de la maquette, pour éviter les badges répétés. Dans l’application réelle, l’origine fictive doit rester identifiable ; une suppression de bruit ne doit pas faire passer une simulation pour une publication officielle.

Principes communs : Graphite, typographie système, une action principale, absence de boutons « Détails », pas de cartes imbriquées, sources et dates en second niveau, accès aux réglages discret. Aucun mouvement décoratif. Les proportions et les matières sont des intentions à traduire ensuite en SwiftUI / AppKit, pas la preuve d’un rendu natif déjà réalisé.

Vérifications : les cinq compositions ont été vues dans le navigateur ; le changement de composition fonctionne au clavier ; le mode sombre a été contrôlé sur Journal et Horizon. Aucun test fonctionnel Swift n’est requis pour ces maquettes indépendantes.
