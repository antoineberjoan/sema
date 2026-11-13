# Lexique

Les mots du métier, tels que le code les écrit. Un terme n'entre ici que lorsqu'il porte un concept partagé. Les noms publics et les formats externes gardent leur contrat.

| Concept | Nom dans le code | Sens |
| --- | --- | --- |
| Série économique | `series`, `MarketSeries` | Série avec origine, unité, source et observations |
| Identifiant d’une série | `seriesID` | Identité précise ; distincte du fournisseur |
| Identifiants suivis | `followedSeriesIDs` | Sélection personnelle ordonnée |
| Favoris | `favoriteIDs` | Identifiants épinglés ; seuls ceux de la sélection suivie s’affichent |
| Point publié | `observation`, `MarketObservation` | Valeur et date d’observation, distinctes de sa mise à jour |
| Descripteur source | `descriptor` | Métadonnées officielles, unité et dimensions |
| Fournisseur | `source`, `StatisticalSource` | Producteur ou connecteur selon le type explicite |
| Règle d’alerte | `rule`, `AlertRule` | Série, seuil, direction et état |
| Seuil | `threshold` | Valeur absolue dans l’unité de la série pour les alertes |
| Dernière évaluation | `lastEvaluatedAt` | Checkpoint de déduplication |
| Date d’observation d’un événement | `observedAt` | Date du point ayant produit l’événement |
| Période affichée | `period`, `HistoryPeriod` | Fenêtre de consultation, distincte de la fréquence |
| Préférences | `preferences`, `AppPreferences` | Choix persistés localement |
| État partagé de l’app | `store`, `AppStore` | Orchestration commune au hub et au bandeau |
| Série affichée | `displayedSeries` | Projection d’affichage d’une série (sens d’une paire de devises inversé à la demande) |
| Mouvement inhabituel | `ratio` | Variation de la séance rapportée à l’écart-type des 20 précédentes (type UnusualMove) |
| Surveillance | `moveWatches` | Règles `unusualMove` d’un repère, activées par la cloche |
| Sensibilité | `multiplier` | Multiple de l’habituel qui déclenche une alerte, global (type MoveSensitivity) |
| Contexte d’une séance | `peers`, `releases`, `headlines` | Faits datés du même jour, réunis par DayContext |
| Fait numéroté | `ContextFact` | Fait transmis à un rédacteur, seul matériau citable |
| Synthèse | `SummaryCheck`, `kept`, `hiddenCount` | Phrases vérifiées contre les faits ; rédacteur choisi dans Réglages (SummaryWriter) |
| Rang d’une séance | `months` | Depuis quand une séance aussi forte ne s’était pas produite (SessionRank) |
| Agenda d’un jour | `items`, `shown` | Lignes classées d’un jour, trois d’abord (DayAgenda, AgendaItem) |
| Brief du matin | `brief`, `BriefPreferences` | Résumé quotidien (MorningBrief) et son horaire |

Dans un objet `Identifiable`, la propriété native reste `id` ; une référence externe à une série reste `seriesID`. Les clés JSON déjà publiées ne sont pas renommées pour satisfaire une convention stylistique. Un nouveau contrat JavaScript utilise le même vocabulaire quand il représente le même concept, sans ajouter aujourd’hui une couche TypeScript au site statique.

## Libellés affichés et noms dans le code

| Libellé affiché | Nom dans le code | Où |
| --- | --- | --- |
| Mes repères | `WorkspaceSection.overview`, `followedSeries` | Rubrique ⌘1 ; groupe de la sidebar ; choix de la recherche ⌘K |
| Favoris | `WorkspaceSection.favorites`, `favorites` | Rubrique ⌘2 |
| Alertes | `WorkspaceSection.alerts` | Rubrique ⌘3 |
| Explorer | `WorkspaceSection.explorer` | Rubrique ⌘4 |
| Aujourd’hui | `WorkspaceSection.brief` | Rubrique ⌘5 ; son résumé envoyé le matin est le brief du matin (type MorningBrief) |
| Aperçu | `previewSeries`, `previewDescriptor` | Panneau d’Explorer avant l’ajout d’un repère |
