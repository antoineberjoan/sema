# Catalogue Webstat et repères personnels

16 octobre 2026. Plan d’implémentation.

## Résultat attendu

Un utilisateur peut découvrir les séries accessibles avec sa clé Webstat, examiner leur définition, consulter leur historique et suivre celles qui l’intéressent. Les 13 repères actuels deviennent une sélection de départ modifiable. Aucune liste manuelle ne doit fermer l’accès au reste du catalogue. Une indisponibilité fournisseur ou une unité non interprétée est expliquée dans la fiche.

Le périmètre reste Webstat. L’utilisateur cherche une série par son nom, ses dimensions ou son code ; il n’a pas à renseigner une URL d’API. La clé personnelle reste dans le Trousseau et dans l’en-tête d’authentification des requêtes Webstat.

## Parcours et interface

### Recherche rapide

⌘K s’ouvre sur « Mes repères », avec les résultats locaux immédiats. Un sélecteur natif permet de passer à « Catalogue Webstat » en conservant la requête. Les flèches déplacent la sélection ; Entrée ouvre la fiche ; Échap ferme et rend le focus au contrôle d’origine. Le panneau conserve sa hauteur pendant la recherche.

Un résultat affiche le titre, le pays ou la zone, la fréquence et l’unité. Un libellé long reste accessible en entier dans la fiche. Deux séries proches doivent pouvoir être distinguées sans dépendre de leur code technique. Le résultat déjà suivi porte un état « Ajouté ».

### Exploration complète

Une entrée discrète « Explorer » dans la sidebar ouvre le catalogue dans la fenêtre principale. La recherche et les filtres partagent le même modèle que ⌘K. Un contrôle « Filtres » révèle progressivement jeu de données, zone et fréquence ; seuls les filtres actifs restent affichés. Parcourir sans texte est possible via les jeux de données.

La liste de résultats garde sa position et son focus lorsqu’une fiche est ouverte puis refermée. Elle utilise des lignes sobres, une sélection douce et une seule surface d’aperçu. Il n’y a pas une carte avec ombre et bordure par résultat.

### Fiche de série

La fiche montre le titre officiel, sa définition, le producteur, l’unité et son échelle, la fréquence, les premières et dernières périodes disponibles, ainsi qu’un lien vers Webstat. La date d’observation et la date de mise à jour de la source restent distinctes.

L’historique se charge à l’ouverture. La valeur sous le graphique suit le point survolé ; la dernière valeur reste la référence au repos. « Ajouter à mes repères » conserve la série et son cache. La confirmation transforme le bouton en « Ajouté » sans fermer brutalement la fiche. Une action explicite permet ensuite d’ouvrir le repère ou de créer une alerte.

### Espace personnel

Panorama présente les séries suivies ; Favoris constitue le sous-ensemble épinglé, notamment dans la barre de menus. L’ordre est personnel et persistant, modifiable par déplacement et par actions clavier. Les familles actuelles ne doivent pas empêcher l’affichage d’un nouveau jeu de données.

Retirer la dernière série produit un écran vide utile avec « Explorer les repères ». Si une série porte des alertes, le retrait précise qu’elles seront mises en pause et conservées. Un échec de sauvegarde annule la mutation visible ; aucun retrait silencieux de règles.

## États à concevoir avant le branchement

| Situation | Réponse de l’interface |
| --- | --- |
| Aucune clé | Recherche locale disponible ; connexion Webstat proposée pour le catalogue. |
| Saisie en cours | Résultats locaux immédiats ; recherche distante après une courte pause, annulable. |
| Requête plus ancienne terminant en retard | Elle ne remplace jamais les résultats de la requête courante. |
| Catalogue en chargement | Indication discrète dans la zone de résultats, géométrie stable. |
| Aucun résultat | Reformuler ou retirer un filtre ; aucun résultat fictif ajouté. |
| Série sans observations | Fiche descriptive consultable, historique indisponible expliqué. |
| Hors connexion | Repères et historiques déjà en cache consultables, date du cache visible. |
| Erreur, quota ou accès refusé | Message local avec action adaptée ; la sélection et le cache restent présents. |
| Série ancienne ou interrompue | Dernière publication clairement indiquée ; aucune apparence de cotation en direct. |
| Métadonnées ambiguës | Codes et valeurs source consultables ; calcul dérivé ou alerte suspendu avec raison explicite. |

## Données et architecture

Le [guide Webstat](https://webstat.banque-france.fr/pages/guide-migration-api/?flg=fr-fr) décrit quatre tables techniques : `webstat-datasets` pour découvrir les jeux, `series` pour les séries et leurs métadonnées, `codelists` pour traduire les dimensions et attributs, et `observations` pour les valeurs historiques. La recherche est filtrable et les observations se récupèrent par clé de série.

### Modèles

- Introduire une description de série indépendante de ses observations : clé Webstat stable, jeu de données, titre court et long, producteur, dimensions, attributs et bornes historiques. Conserver les métadonnées brutes pour les codes inconnus.
- Faire évoluer les unités au-delà de l’énumération actuelle. Garder unité, multiplicateur, décimales, devise éventuelle et convention de variation séparés. Un montant en millions ne doit pas être multiplié deux fois.
- Étendre les fréquences au moins à quotidienne, ouvrée, hebdomadaire, mensuelle, trimestrielle, semestrielle et annuelle ; préserver le code source inconnu. Les bornes de période fournies par Webstat font référence.
- Conserver `Decimal` pour les valeurs et calculs. Les pourcentages se comparent en points ; les indices et montants ne reçoivent pas automatiquement une variation relative si cette lecture serait ambiguë, notamment autour de zéro ou avec des valeurs négatives.
- Ajouter la sélection ordonnée des séries suivies aux préférences. Les favoris épinglent ces séries ; ils ne servent pas à stocker tout le catalogue.

### Requêtes et cache

Étendre le client Webstat existant avec la découverte et la recherche, sans nouveau fournisseur ni framework. Valider les paramètres et échapper les expressions de recherche. Aucune URL arbitraire ne reçoit la clé.

Charger les résultats par pages, avec total ou état de fin. Charger les listes de codes nécessaires au jeu consulté et les conserver localement. Une pause initiale de 250 ms après saisie limite les requêtes ; annuler les recherches dépassées. Cette durée sera réglée dans le prototype.

Télécharger les observations uniquement pour les séries consultées ou suivies. Regrouper les actualisations avec des lots bornés ; une série en erreur ne doit pas effacer celles déjà obtenues. Chaque série garde son état et sa date de synchronisation.

Les périodes de lecture actuelles restent rapides. Ajouter « Tout » pour atteindre le début publié de la série : charger les périodes anciennes par tranches à la demande, afficher la couverture réellement obtenue et permettre d’annuler. La limite actuelle de six années téléchargées ne devient pas une limite définitive du produit. Pour les longues séries, réduire seulement les points dessinés si nécessaire ; les valeurs originales restent disponibles pour l’analyse et la lecture détaillée.

Une actualisation inclut une fenêtre de recouvrement pour les révisions récentes ; un rechargement complet explicite permet de récupérer les corrections plus anciennes. Réviser une observation déjà évaluée ne déclenche pas une nouvelle alerte historique.

### Compatibilité

Créer une migration versionnée et atomique des préférences et du cache. Mapper les identifiants actuels (`fr10`, `eurusd`, etc.) vers les clés Webstat en préservant favoris, alertes et checkpoints. Dédupliquer une série présente dans la sélection initiale et ajoutée depuis le catalogue. Les anciennes préférences de fonds restent conservées.

Ne pas écrire sur des préférences illisibles. Après migration, une sélection vide est valide : remplacer les accès implicites à `series[0]` par un état vide explicite.

### Alertes

Étendre les alertes de seuil absolu aux nouvelles séries dont la valeur et l’unité sont interprétées. Le champ et la confirmation affichent la même échelle que le graphique : « 120 millions d’euros » ne signifie pas « 120 euros ». Le franchissement reste strict et la déduplication persistante.

L’ajout d’une série initialise le checkpoint sur la dernière observation connue, sans avalanche d’alertes historiques. Les règles sont évaluées à l’actualisation ; le catalogue ouvert n’ajoute pas une surveillance permanente ou une tâche lorsque le Mac est éteint.

## Lots et fichiers concernés

| Lot | Travail | Zones principales |
| --- | --- | --- |
| C1 | Prototype clavier de recherche, filtres et aperçu sur fixtures explicites | `Features/SeriesSearchView.swift`, futur écran Explorer, `WorkspaceView.swift` |
| C2 | Description générique, recherche distante et interprétation des métadonnées | `MarketCore/WebstatClient.swift`, `MarketSeries.swift`, tests du client |
| C3 | Séries suivies, historique progressif, migration et erreurs par série | `AppStore.swift`, `PreferencesStore.swift`, `LocalStorage.swift`, `HistoryChart.swift` |
| C4 | Alertes, accessibilité, revue visuelle et documentation | `AlertsView.swift`, formatage, tests des seuils, `PRODUCT.md`, landing après validation |

## Critères de livraison

- Rechercher et ajouter au moins un taux hors sélection, un indice, un montant avec multiplicateur et une série trimestrielle ou annuelle provenant de jeux différents. Comparer leurs valeurs et périodes à Webstat.
- Tester les codes exacts, accents, doublons, filtres, pagination et réponses désordonnées. Les exemples de fixtures ne sont jamais présentés comme un test de production.
- Vérifier les zéros, valeurs négatives, observations manquantes, révisions et unités inconnues ; aucun `%`, « quotidien » ou « millions » inventé par défaut.
- Relancer après ajout, retrait et réorganisation ; retrouver la sélection, le cache, les alertes et les checkpoints. Tester la migration d’un fichier v1 et un fichier illisible.
- Parcourir au clavier : ouvrir ⌘K, filtrer, prévisualiser, ajouter, revenir au résultat, fermer. Vérifier VoiceOver, les six thèmes, clair/sombre et Réduire les animations.
- Exécuter `./scripts/check.sh`, compiler le bundle et vérifier le parcours dans l’app native. Tester le réseau avec une clé personnelle autorisée, sans la copier dans les fixtures ou journaux.

Les animations de sélection visent 120–160 ms ; l’apparition de l’aperçu 180–240 ms avec un déplacement inférieur à 8 pt. Aucun mouvement n’est nécessaire pour rendre les actions disponibles. Les interruptions repartent de l’état visible, sans empiler des délais.
