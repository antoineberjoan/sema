# Produit et périmètre

## Promesse

Permettre à un professionnel du patrimoine de consulter ses repères économiques issus de sources publiques et définir des alertes de seuil, sans disperser son attention entre plusieurs sites.

L’incrément local du 16 octobre ouvre sept catalogues publics supplémentaires, avec leurs jeux et dimensions : [contrat et limites](PUBLIC-CATALOGUES.md). Les treize repères Webstat et les exemples proposés ne limitent aucune sélection personnelle. Les contrats Webstat de la version 0.3 ci-dessous restent applicables à ce connecteur ; l’actualisation et les alertes sont désormais partagées entre sources.

Les sources activables, le profil local facultatif, les équivalences vérifiées et le soutien Ko-fi sont décrits dans [PERSONALIZATION.md](PERSONALIZATION.md). « Mon espace » ouvre désormais Profil dans les réglages natifs ; les clés et interrupteurs sont réunis dans Sources.

## Direction retenue

Direction **Focus avec sidebar escamotable**, validée par Antoine le 17 octobre : un seul repère et son historique dominent le hub, sans carte de détail imbriquée. Le bandeau de verre reste la seconde surface de consultation rapide. La sidebar réunit la recherche, les rubriques et la sélection ordonnée ; « Mon espace » reste fixé en bas, en dehors de la liste défilante. Références : Hoy, Helumi, Monocle, Klack, Alcove et [Resurf](https://resurf.so/). L’app reste sobre ; le mouvement sert les changements d’état et les sélections.

Deux surfaces partagent la même information :

1. Bandeau de favoris : vue d’ensemble sur le bord choisi de l’écran courant. Cartes et mini-courbes défilent horizontalement en haut et en bas, verticalement à gauche et à droite.
2. Fenêtre principale : sélection des séries, historiques et gestion des alertes macroéconomiques.

## Contrats de la version 0.3 locale

| Fonction | Comportement attendu |
| --- | --- |
| Présence macOS | Icône dans la barre de menus uniquement, sans icône dans le Dock. Le clic gauche ouvre le bandeau ; le clic droit propose Réglages…, Rechercher des mises à jour… et Quitter sema, avec icônes SF Symbols et séparateurs natifs. La recherche de mises à jour ouvre la page des versions du dépôt public de distribution : téléchargement manuel ou Homebrew, sans vérification ni installation automatiques. Fermer la fenêtre principale laisse sema accessible dans la barre de menus. |
| Bandeau | Clic sur l’icône sema ou ⌘⇧B : favoris dans leur ordre personnel, période commune 3 mois / 1 an / 3 ans / 5 ans / Tout, directement visible dans une seule barre native sans bouton Plus, valeurs, variations, courbes et dates en cache. Défilement natif au trackpad et au clavier si nécessaire. Clic sur une carte pour ouvrir son détail dans le hub ; clic extérieur, Échap, changement d’application ou d’espace pour fermer. Une sélection sans favori propose de les choisir dans le hub. Position haut/bas/gauche/droite persistante dans Apparence. Cartes en verre natif sur un panneau transparent, sans grand fond commun. En haut et en bas, le rail Repère de 84 pt réunit cinq périodes et les réglages en pied, sans grand fond commun ; chaque libellé garde une petite matière native pour rester lisible sur le bureau. Ce rail et les cartes font 216 pt de haut, sans barre en dessous. Jusqu’à quatre favoris sont visibles selon la largeur, en plus de la signature fixée hors du défilement, toujours visible même sans favori. Les cartes compactes mesurent de 208 à 232 pt de large pour 216 pt de haut. Le cartouche suit la palette choisie, y compris Graphite. Les badges d’origine et la flèche décorative sont retirés du bandeau ; le détail et le libellé accessible conservent l’origine fictive. Quatre favoris sont proposés aux nouvelles installations, sans modifier les choix déjà enregistrés. Le bord supérieur des cartes reste à 12 pt de la zone visible. À gauche et à droite, le sélecteur compact reste sous les cartes. Signature Palier tracée puis texte révélé plus lentement, sans nom répété ni bouton Rejouer ; état final immédiat avec Réduire les animations. |
| Focus | Un grand historique sur la surface de la fenêtre, valeur et unité réunies, variation dans un badge de la palette et action d’alerte réunies à côté de la valeur (repli vertical si nécessaire), périodes en haut. La barre d’outils garde le bouton de sidebar sans répéter le nom de l’app. Le clic sur son icône ouvre ou ferme la sidebar à demeure ; ⌃⌘S reste disponible. Fermée, elle apparaît en superposition au survol de l’icône, reste ouverte tant que le pointeur est sur l’icône ou le panneau, puis se referme après une courte tolérance de passage. Le graphique ne se déplace pas pendant cet aperçu. Échap la replie depuis Focus hors feuille. Les accès rapides aux repères apparaissent en bas uniquement lorsqu’elle est repliée. Hors saisie et feuille, ↑ / ↓ sélectionne directement le voisin dans l’ordre personnel. ⌘↑ / ⌘↓ ouvre le sélecteur de verre et parcourt les repères en boucle ; relâcher ⌘ ou presser Entrée ouvre le choix, Échap ou un changement de fenêtre annule sans modifier le graphique. Le hub propose 3 mois, 1 an, 3 ans, 5 ans et Tout selon la couverture reçue. La sidebar conserve l’ordre personnel, les déplacements par glissement ou ⌘⌥↑ / ⌘⌥↓ et le retrait avec confirmation. « Mon espace » ouvre le profil local depuis son pied fixe. Une sélection vide reste valide. « Donnée du… » ou la période complète identifie la date de la valeur sous le graphique, avec la mention fictive éventuelle. Le popover de source distingue « Actualisé dans sema » avec la date et l’heure de téléchargement. Le petit bouton natif secondaire « Créer une alerte » est aligné sous le badge et reste soumis aux règles de source et d’unité ; il n’est plus répété sous le graphique. Les définitions et métadonnées restent accessibles à la demande. |
| Explorer | L’entrée présente les sources actives et leur domaine. Choisir un catalogue ouvre la recherche, les résultats et un aperçu avant ajout ; Sources revient au choix initial. Webstat déconnecté propose une seule connexion, sans masquer les accès publics. Filtres, détails du jeu et code exact se révèlent à la demande. Les choix de dimensions restent explicites ; une valeur unique est montrée sans bouton. Les erreurs et reprises restent locales au catalogue ou au repère. Aucun pied de page générique. |
| Recherche | ⌘K propose Mes repères et Catalogue Webstat. Recherche locale immédiate, catalogue après 250 ms, annulation des requêtes dépassées, pagination de 50, code exact, filtres jeu/zone/fréquence. Flèches pour choisir, Entrée pour ouvrir l’aperçu, Échap pour fermer. |
| Raccourcis | ⌘1 Mes repères, ⌘2 Favoris, ⌘3 Alertes et ⌘R pour actualiser Webstat lorsque la connexion est disponible. ⌘⇧B ouvre ou referme le bandeau des favoris. Deux raccourcis globaux ouvrent le bandeau (⌃⌥B) et le hub (⌃⇧H), personnalisables, effaçables et réinitialisables dans Réglages → Raccourcis. Les flèches ↑/← et ↓/→ passent respectivement au repère précédent et suivant ; avec ⌘, elles pilotent le même sélecteur visuel, validé au relâchement de ⌘. Les conflits avec une autre action sema, les raccourcis de menu, macOS ou une réservation exclusive sont refusés sans remplacer le choix sauvegardé. Ils restent actifs uniquement tant que sema tourne. |
| Cotation des devises | Un bouton ↔ à côté de l’étoile inverse les taux de change de référence BCE reconnus (Webstat, accès BCE direct et démonstration). Le titre, l’unité, chaque observation, la variation et les infobulles suivent le sens choisi. Les paires vérifiées s’affichent avec leur titre court français et leur code de devise ; le libellé et l’unité du fournisseur restent accessibles dans les informations de source. Préférence locale par paire, commune aux cartes, au détail et au bandeau, sans nouvel appel réseau. Les alertes et les métadonnées gardent la cotation publiée ; le détail le précise en lecture inversée. Une observation nulle ou négative empêche l’inversion. |
| Graphiques | Au survol, afficher la date, la valeur et l’unité du point historique le plus proche dans une infobulle, avec un repère sur la courbe et la même lecture sous le graphique. Effacer la sélection lorsque la série ou la période change. |
| Origine | Identifier clairement les données fictives et les repères Webstat réellement téléchargés ; conserver leur producteur et leur période. |
| Favoris | Épingler un sous-ensemble des séries suivies ; retrouver sélection, ordre et favoris après relancement. Retirer une série met ses alertes en pause et conserve leur règle et le cache. |
| Webstat | Connecter une clé personnelle et découvrir les séries accessibles, sans liste fermée. Les 13 repères constituent une sélection initiale. Actualisation par série avec conservation du cache en cas d’erreur. Six ans chargés à l’ouverture ; « Tout » permet de charger les tranches anciennes jusqu’au début publié et d’annuler. |
| Clé | Valider la clé avant de l’enregistrer dans le Trousseau de ce Mac ; pouvoir la remplacer ou la retirer sans effacer le cache. |
| Réglages | « Mon espace » en bas de la sidebar ouvre les réglages natifs, également accessibles par le menu sema et ⌘,. La fenêtre réunit une sidebar fixe avec recherche de rubrique, les groupes natifs et des choix visuels de mode/palette ; « Mon espace » reste fixé en bas. La recherche porte uniquement sur les rubriques et leurs mots-clés. Aucun engrenage ne se répète dans la barre d’outils du hub. |
| Apparence | Graphite par défaut. Choisir Graphite, Sarcelle, Menthe, Lavande, Bleu ciel ou Bleu polaire dans les réglages. Le mode Système / Clair / Sombre se choisit indépendamment de la palette et persiste localement. Le verre des cartes reprend une teinte discrète de la palette, Graphite restant neutre ; Réduire la transparence et Augmenter le contraste conservent une surface opaque. Palette et mode s’appliquent aux deux surfaces. Dans Apparence, les curseurs Transparence, Teinte et Grain ajustent les surfaces du bandeau, avec un aperçu du premier favori et une remise à zéro limitée au verre. Le flou reste natif macOS ; la transparence règle le voile de contraste, la teinte est inactive en Graphite et le grain reste statique. Ces trois réglages persistent indépendamment de la palette et du mode. La marque et l’icône d’app restent monochromes. |
| Retours | « Une idée ou un bug ? » dans le cartouche du bandeau ouvre un formulaire Notion public dans le navigateur. Sujet, type et description obligatoires ; e-mail facultatif. Les réponses et le suivi restent privés. |
| Alertes | Créer une règle « passe au-dessus/en dessous » sur un repère macro, la mettre en pause, la supprimer et tester un franchissement explicite. Vérifier les nouvelles observations à chaque actualisation Webstat. |
| Notifications | Signaux de la session visibles dans l’app ; notifications système optionnelles après activation. Déduplication persistante par règle et date d’observation. |

### Catalogue et fidélité des données

L’aperçu affiche le titre et la définition officiels, la fréquence, l’unité et son multiplicateur, le producteur, les bornes publiées, la base d’un indice, les dates d’observation et de mise à jour, ainsi que les métadonnées brutes. Les libellés proviennent des listes de codes du jeu. Une définition longue contradictoire reste visible ; fréquence et périodes de la source font référence.

Les nombres conservent l’échelle de `obs_value` : un encours en milliards n’est pas multiplié à nouveau. Toute unité explicitement traduite par Webstat peut porter un seuil absolu ; `_Z`, `_X`, une unité sans libellé connu ou un multiplicateur absent suspendent les alertes. Une variation relative n’est pas inventée sur les indices et montants. Les données manquantes restent absentes du graphique.

Les préférences et le cache v1 migrent atomiquement vers v2, avec copie `.v1-backup`. Les identifiants locaux deviennent les clés Webstat, les anciennes règles et checkpoints sont préservés. Les préférences illisibles ne sont pas remplacées. La migration marque les utilisateurs existants comme déjà accueillis.

## Hors de cette version

- Fonds suivis, données de fonds et intégration Morningstar. Les anciennes préférences de fonds sont conservées sans être exposées.
- Surveillance avec sema quittée ou le Mac en veille ; serveur de notifications.
- Compte utilisateur, synchronisation, abonnement et facturation.
- Widgets de bureau et îlot autour de l’encoche.
- Notarisation Apple, distribution sur le Mac App Store et bêta client signée Developer ID.

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

## Actualisation quotidienne

Décision d’Antoine dans le chat du 17 octobre 2026, reportée dans Notion Produit : au lancement et au réveil, contrôle de fraîcheur des séries suivies et connectées. Seules celles synchronisées depuis au moins 24 h sont récupérées. L’échéance suivante reste active avec le hub fermé tant que sema tourne. Une fermeture/réouverture ne réinitialise pas la fraîcheur conservée dans le cache. Les nouvelles observations sont évaluées par le moteur d’alertes existant ; les notifications restent désactivées jusqu’à activation explicite. ⌘R force une actualisation. Un échec conserve les données ; prochain essai quotidien ou manuel.
