# Vocabulaire du code

Référence de nommage, pas registre de toutes les variables. Ajouter un terme seulement lorsqu’il porte un concept partagé. Les noms publics et formats externes conservent leur contrat.

| Concept | Nom dans le code | Sens |
| --- | --- | --- |
| Série économique | `series`, `MarketSeries` | Série avec origine, unité, source et observations |
| Identifiant d’une série | `seriesID` | Identité précise ; distincte du fournisseur |
| Identifiants suivis | `followedSeriesIDs` | Sélection personnelle ordonnée |
| Favoris | `favoriteIDs` | Sous-ensemble épinglé de la sélection |
| Point publié | `observation`, `MarketObservation` | Valeur et date d’observation, distinctes de sa mise à jour |
| Descripteur source | `descriptor` | Métadonnées officielles, unité et dimensions |
| Fournisseur | `source`, `StatisticalSource` | Producteur ou connecteur selon le type explicite |
| Règle d’alerte | `rule`, `AlertRule` | Série, seuil, direction et état |
| Seuil | `threshold` | Valeur absolue dans l’unité de la série pour les alertes actuelles |
| Dernière évaluation | `lastEvaluatedAt` | Checkpoint de déduplication |
| Date d’observation d’un événement | `observedAt` | Date du point ayant produit l’événement |
| Période affichée | `period`, `HistoryPeriod` | Fenêtre de consultation, distincte de la fréquence |
| Préférences | `preferences`, `AppPreferences` | Choix persistés localement |
| État partagé de l’app | `store`, `AppStore` | Orchestration commune au hub et au bandeau |
| Série publiée / affichée | `publishedSeries` / `displayedSeries` | Cotation source / projection d’affichage |

Dans un objet `Identifiable`, la propriété native reste `id` ; une référence externe à une série reste `seriesID`. Les clés JSON déjà publiées ne sont pas renommées pour satisfaire une convention stylistique. Un nouveau contrat JavaScript utilise le même vocabulaire quand il représente le même concept, sans ajouter aujourd’hui une couche TypeScript au site statique.
