# Produit et périmètre

## Promesse

Permettre à un professionnel du patrimoine de consulter ses repères économiques Webstat et définir des alertes de seuil, sans disperser son attention entre plusieurs sites.

## Direction retenue

Mélange des maquettes **Panorama** et **Atelier** validé par Antoine : douceur et lisibilité du panneau, structure d’une petite app de travail. Références : Hoy, Helumi, Monocle, Klack, Alcove et [Resurf](https://resurf.so/). L’app reste sobre ; le mouvement sert les changements d’état et les sélections.

Deux surfaces partagent la même information :

1. Bandeau de favoris : vue d’ensemble sur le bord choisi de l’écran courant. Cartes et mini-courbes défilent horizontalement en haut et en bas, verticalement à gauche et à droite.
2. Fenêtre principale : sélection des séries, historiques et gestion des alertes macroéconomiques.

## Contrats de la version 0.3 locale

| Fonction | Comportement attendu |
| --- | --- |
| Bandeau | Clic sur l’icône sema ou ⌘⇧B : favoris dans leur ordre personnel, période commune 1 mois / 3 mois / 1 an, valeurs, variations, courbes et dates en cache. Défilement au trackpad ou par flèches si nécessaire. Clic sur une carte pour ouvrir son détail dans le hub ; clic extérieur, Échap, changement d’application ou d’espace pour fermer. Une sélection sans favori propose de les choisir dans le hub. Position haut/bas/gauche/droite persistante dans Apparence. Verre natif, signature tracée puis texte révélé, rejouable sans boucle ; état final immédiat avec Réduire les animations. |
| Panorama | Consulter la sélection personnelle ordonnée ; ajouter depuis Explorer, retirer, déplacer par glissement ou avec ⌘⌥↑ / ⌘⌥↓. Une sélection vide est valide. |
| Recherche | ⌘K propose Mes repères et Catalogue Webstat. Recherche locale immédiate, catalogue après 250 ms, annulation des requêtes dépassées, pagination de 50, code exact, filtres jeu/zone/fréquence. Flèches pour choisir, Entrée pour ouvrir l’aperçu, Échap pour fermer. |
| Raccourcis | ⌘1 Panorama, ⌘2 Favoris, ⌘3 Alertes et ⌘R pour actualiser Webstat lorsque la connexion est disponible. ⌘⇧B ouvre ou referme le bandeau des favoris. Raccourcis internes à sema, sans raccourci système global. |
| Graphiques | Au survol, afficher la date, la valeur et l’unité du point historique le plus proche dans une infobulle, avec un repère sur la courbe et la même lecture sous le graphique. Effacer la sélection lorsque la série ou la période change. |
| Origine | Identifier clairement les données fictives et les repères Webstat réellement téléchargés ; conserver leur producteur et leur période. |
| Favoris | Épingler un sous-ensemble des séries suivies ; retrouver sélection, ordre et favoris après relancement. Retirer une série met ses alertes en pause et conserve leur règle et le cache. |
| Webstat | Connecter une clé personnelle et découvrir les séries accessibles, sans liste fermée. Les 13 repères constituent une sélection initiale. Actualisation par série avec conservation du cache en cas d’erreur. Six ans chargés à l’ouverture ; « Tout » permet de charger les tranches anciennes jusqu’au début publié et d’annuler. |
| Clé | Valider la clé avant de l’enregistrer dans le Trousseau de ce Mac ; pouvoir la remplacer ou la retirer sans effacer le cache. |
| Réglages | « Mon espace » en bas de la sidebar ouvre les mêmes réglages natifs que le bouton de la barre d’outils et le menu sema. |
| Apparence | Graphite par défaut. Choisir Graphite, Sarcelle, Menthe, Lavande, Bleu ciel ou Bleu polaire dans les réglages. Choix local persistant, appliqué aux deux surfaces. La marque et l’icône d’app restent monochromes. |
| Retours | « Une idée ou un bug ? » dans le cartouche du bandeau ouvre un formulaire Notion public dans le navigateur. Sujet, type et description obligatoires ; e-mail facultatif. Les réponses et le suivi restent privés. |
| Alertes | Créer une règle « passe au-dessus/en dessous » sur un repère macro, la mettre en pause, la supprimer et tester un franchissement explicite. Vérifier les nouvelles observations à chaque actualisation Webstat. |
| Notifications | Signaux de la session visibles dans l’app ; notifications système optionnelles après activation. Déduplication persistante par règle et date d’observation. |

### Catalogue et fidélité des données

L’aperçu affiche le titre et la définition officiels, la fréquence, l’unité et son multiplicateur, le producteur, les bornes publiées, la base d’un indice, les dates d’observation et de mise à jour, ainsi que les métadonnées brutes. Les libellés proviennent des listes de codes du jeu. Une définition longue contradictoire reste visible ; fréquence et périodes de la source font référence.

Les nombres conservent l’échelle de `obs_value` : un encours en milliards n’est pas multiplié à nouveau. Toute unité explicitement traduite par Webstat peut porter un seuil absolu ; `_Z`, `_X`, une unité sans libellé connu ou un multiplicateur absent suspendent les alertes. Une variation relative n’est pas inventée sur les indices et montants. Les données manquantes restent absentes du graphique.

Les préférences et le cache v1 migrent atomiquement vers v2, avec copie `.v1-backup`. Les identifiants locaux deviennent les clés Webstat, les anciennes règles et checkpoints sont préservés. Les préférences illisibles ne sont pas remplacées. La migration marque les utilisateurs existants comme déjà accueillis.

## Hors de cette version

- Fonds suivis, données de fonds et intégration Morningstar. Les anciennes préférences de fonds sont conservées sans être exposées.
- Actualisation automatique, exécution en arrière-plan, serveur de notifications.
- Compte utilisateur, synchronisation, abonnement et facturation.
- Widgets de bureau et îlot autour de l’encoche.
- Distribution publique ou bêta client notarialisée.

## Vérification manuelle d’un incrément

1. Ouvrir l’app et le panneau de barre de menus ; sélectionner un indicateur et changer de période.
2. Modifier les favoris dans une surface et vérifier l’autre, puis relancer l’app.
3. Dans les réglages, connecter Webstat ; contrôler les sources, la devise et les dates, ainsi que les vues sur 1 an, 3 ans et 5 ans.
4. Sélectionner un taux ou l’inflation, créer une alerte de seuil, la tester, la mettre en pause puis la supprimer.
5. Contrôler les erreurs réseau et l’absence de perte de préférences.
6. Retirer la clé ; vérifier que l’actualisation est désactivée et que les dernières données restent consultables après relancement.
7. Changer de thème dans Apparence, vérifier la fenêtre et le panneau, puis relancer pour vérifier la persistance.

8. Ouvrir la recherche avec ⌘K, saisir « OAT », ouvrir au clavier ; contrôler les résultats sans accents, la navigation par flèches, la fermeture avec Échap et les raccourcis de rubrique.

9. Dans Explorer, rechercher un code exact, changer de jeu, de fréquence et de zone ; ouvrir un aperçu puis l’ajouter. Rechercher aussi une unité non interprétée : vérifier l’explication et l’absence d’alerte active.
10. Réorganiser les séries, retirer un repère avec alerte puis le dernier repère ; relancer et vérifier les états persistants.
11. Choisir « Tout », charger les périodes anciennes puis annuler ; contrôler la couverture réellement reçue et la première période publiée. Tester le rechargement explicite et la révision sans nouvelle alerte historique.

12. Ouvrir le bandeau depuis l’icône et ⌘⇧B ; changer la période, ouvrir une carte, fermer avec Échap et un clic extérieur. Fermer le hub puis vérifier la réouverture du bandeau. Contrôler les états sans favori et avec suffisamment de favoris pour défiler.
