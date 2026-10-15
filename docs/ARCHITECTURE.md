# Architecture

## Organisation actuelle

Un seul package Swift, deux cibles de production et une cible de tests. Aucun service distant propre à Sema.

```mermaid
flowchart TB
    Menu["Panneau de barre de menus"] --> Store["AppStore · MainActor"]
    Window["Fenêtre principale"] --> Store
    Store --> Core["MarketCore · modèles et règles"]
    Store --> Webstat["Webstat · URLSession · clé personnelle"]
    Store --> Keychain["Trousseau macOS · Security"]
    Store --> Local["Préférences et cache locaux"]
    Store --> Notification["Notifications de démonstration"]
```

### MarketCore

- `MarketSeries` : série typée, origine, source et observations triées et dédupliquées.
- `AlertRule` / `AlertEvaluator` : seuil, direction, part exacte, évaluation pure et déduplication par date d’observation.
- `ECBExchangeRateClient` : téléchargement des 90 derniers jours, validation HTTP et lecture XML sans entités externes.
- `WebstatClient` : export JSON groupé des 13 séries explicites sur cinq ans ; clé dans le header `Authorization`, validation HTTP, valeurs manquantes et dates d’observation. Un export incomplet n’est pas appliqué.
- `PreferencesStore` : document JSON versionné, lecture explicite des erreurs et écriture atomique.
- `DemoCatalog` : fixtures fixes et identifiées comme telles, sans dépendance au réseau.

### SemaMac

- `AppStore` est l’état partagé et le point de coordination. Il ne dessine pas l’interface.
- `Features` présente les données et émet les actions utilisateur.
- `DesignSystem` contient les couleurs adaptées à l’apparence système, les composants partagés et les graphiques.
- `Infrastructure` contient les effets dépendants de macOS : chemins de stockage et notifications système.
- `WebstatKeychain` utilise Security dans un acteur séparé du MainActor. La clé n’est jamais incluse dans les fichiers de préférences, dans le cache, dans une URL ou dans le binaire. Aucun service serveur ni bibliothèque externe n’est ajouté.

Les états de sélection sont partagés volontairement entre panneau et fenêtre. Une action sur un favori doit être visible immédiatement dans les deux.

## Persistance

Les préférences et les règles restent un petit document local. Le cache des devises est séparé, car il peut être régénéré. Les préférences illisibles ne sont jamais remplacées automatiquement.

Les historiques restent immuables. Une connexion Webstat réussie remplace les séries macro reçues et conserve les fonds de démonstration. Le cache `webstat-cache.json` est écrit atomiquement ; l’ancien cache BCE peut encore être lu si aucun cache Webstat n’existe. Aucun appel BCE direct n’est exposé dans l’interface actuelle.

La connexion valide les données avant d’enregistrer la clé. Une erreur HTTP, un quota atteint ou une erreur de décodage conserve le cache et les données affichées ; aucun nouvel essai automatique ne tourne. Le bouton d’actualisation utilise ensuite la clé du Trousseau. Retirer la clé conserve volontairement les données publiques déjà téléchargées. Le cache est relu au lancement, l’actualisation reste manuelle.

Les observations Webstat conservent la fin de période, le statut et la date de mise à jour source. Une période mensuelle peut se terminer dans le futur si le taux est déjà applicable dans le mois courant. Les fenêtres des séries mensuelles utilisent des mois calendaires. Les caches antérieurs, sans ces métadonnées optionnelles, restent lisibles.

## Alertes

Le moteur est testable et indépendant du transport de notification. La version 0.1 n’exécute ce moteur que lors d’une simulation explicite ; aucun minuteur ou service ne surveille les fonds.

Une surveillance future s’ajoutera à l’orchestration. Si elle doit continuer indépendamment du Mac, elle exigera un service côté serveur. Une notification APNs n’assure pas une réception instantanée sur un appareil éteint ou hors ligne.

## Évolutions conditionnelles

- Introduire un fournisseur supplémentaire uniquement lorsque son contrat de données et ses droits sont validés.
- Ajouter une interface commune aux fournisseurs si plusieurs implémentations doivent réellement être substituées ; ne pas construire ce cadre à l’avance.
- Passer à SwiftData si le volume ou les requêtes locales le justifient ; une migration devra préserver les préférences existantes.
- Ajouter un projet Xcode d’app si les besoins de distribution, d’assets ou d’entitlements le rendent utile. Le package Swift et le script de bundle sont la source actuelle de compilation.
