# Un repère de départ a un nom de départ et un code de série, lus tous deux à l'exécution

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Les seize repères de départ ont deux identifiants. Le **nom de départ** (« fr10 », « eurusd ») est propre au produit. Le **code de série** Webstat (`FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD`) est l'identité d'une série dans les observations, les favoris et les alertes. Les deux sont lus pendant l'exécution :

- Le nom de départ clé les règles de lecture (`SeriesExplanation`), les mots de recherche (`SeriesSearch`), l'écran d'accueil, les préférences par défaut et la sélection initiale. `WebstatMapping` donne ce nom comme identifiant aux séries qu'il décode, avant leur fusion.
- Le code de série identifie la série partout ailleurs. `WebstatStarter.starterKey` passe de l'un à l'autre.

C'est un seul concept avec deux noms.

## Décision

Le code garde les deux, sans changer de comportement. Le nom de départ est un `slug` de `WebstatStarter` ; `starterKey` donne le code de série. Un identifiant enregistré dans un fichier passe par `IdentifierMigration`, appelée au seul chargement d'un fichier ([relecture des versions de fichiers](2026-11-12-relecture-des-versions-de-fichiers.md)).

## Conséquences

C'est le seul écart connu de code qui demande un Mac : clé tout par le code de série (règles de lecture, recherche, accueil, préférences par défaut, sélection initiale, décodage de `WebstatMapping`) et retirer `starterKey`.

**Condition de retrait** : la compilation et les tests passent sur le Mac d'Antoine. Le re-clé se fait alors dans un lot, avec ses tests.
