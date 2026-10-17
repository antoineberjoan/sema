# Plan sema pour le catalogue et la distribution

En cours : [navigation clavier et bandeau Repère](plans/keyboard-navigation.md).

Historique : [réglages avec sidebar en cours de simplification](plans/settings-sidebar.md) ; [socle agentique validé et livré en PR brouillon](plans/agent-foundation.md). Les plans ci-dessous sont conservés dans leur état documenté ; certains lots ont depuis été implémentés. Leur statut doit être réconcilié avec les preuves et l’arbitrage d’Antoine avant de les reprendre comme tâches. Le périmètre courant est décrit dans [PRODUCT.md](PRODUCT.md).

16 octobre 2026. Direction validée avec Antoine ; fonctionnalités ci-dessous à réaliser. Le logo de barre de menus à 2 pt est déjà intégré et compilé.

sema doit permettre à chaque utilisateur de composer ses repères dans le catalogue Webstat. La première installation doit prolonger la même identité, du site au DMG puis à l’accueil natif. L’ouverture du catalogue et la distribution sont deux chantiers distincts, avec une exigence commune : une interface calme, précise et attentive.

## Deux plans exécutables

- [Catalogue Webstat et repères personnels](plans/catalogue-webstat.md) : recherche, prévisualisation, métadonnées, historique, persistance, alertes et migration.
- [Téléchargement et premier lancement](plans/distribution.md) : page dédiée, DMG personnalisé, accueil SwiftUI, Homebrew et publication.

## Ordre de réalisation

| Lot | Livrable | Condition de fin |
| --- | --- | --- |
| 0 | Logo de barre de menus à 2 pt | Bundle compilé et comparaison native clair/sombre. Fait. |
| 1 | Prototype natif du parcours catalogue | Trouver, distinguer, prévisualiser et ajouter une série au clavier ; états vide, chargement et erreur lisibles. |
| 2 | Catalogue et données génériques | Recherche réelle, métadonnées interprétées, historiques chargés à la demande et cache conservé en cas d’échec. |
| 3 | Repères personnels et alertes | Migration sans perte, ajout/retrait/réorganisation persistants et seuils dans la bonne unité. |
| 4 | Prototype de téléchargement et d’accueil | Un parcours continu, paramètres d’animation réglables et réduction des animations vérifiée. |
| 5 | DMG et version distribuable | Installation testée sur un autre Mac ou compte macOS, version et empreinte vérifiées, absence de données personnelles. |
| 6 | Téléchargement et Homebrew actifs | Lien accessible dans l’audience choisie, installation et mise à jour Homebrew testées, landing fidèle à la version livrée. |

Le prototype du lot 4 peut être préparé indépendamment des données. L’accueil final dépend des choix de repères réalisés dans les lots 1 à 3. Les boutons de téléchargement et la promesse de catalogue ouvert ne deviennent actifs qu’avec les livrables correspondants.

## Exigence de design commune

SF Pro système, SwiftUI et SF Symbols dans l’app ; fond neutre, accent choisi par l’utilisateur, chiffres alignés. Les listes sont structurées par l’espace et la hiérarchie typographique. Les ombres servent les surfaces flottantes ; le focus clavier et les séparateurs utiles restent visibles.

Chaque lot passe par trois revues distinctes : parcours et contenu, présentation, puis interactions. La validation comporte l’état au repos et le comportement réel : retour arrière, interruption d’une animation, saisie rapide, erreur réseau et reprise. Une capture seule ne valide pas une animation.

Les séquences sont décrites avant codage, avec des constantes nommées pour les durées et déplacements. Un réglage réservé au développement permet de comparer immédiatement les valeurs. Les valeurs proposées dans les plans sont des points de départ sema, pas des prescriptions d’Interface Craft.

## Références relues

Les leçons membres suivantes d’Interface Craft guident la méthode : [Separation of Concerns](https://www.interfacecraft.dev/library/separation-of-concerns), [Conceptual Depth](https://www.interfacecraft.dev/library/conceptual-depth), [Live Tuning](https://www.interfacecraft.dev/library/live-tuning), [Animations as Proof of Care](https://www.interfacecraft.dev/library/animations-as-proof-of-care), [Less, but Better](https://www.interfacecraft.dev/library/less-but-better) et [Facets of Quality](https://www.interfacecraft.dev/library/facets-of-quality). Les critères de sema privilégient la précision, la rapidité, la retenue et la continuité.

Les contrats de la version actuelle restent décrits dans [PRODUCT.md](PRODUCT.md). Ce plan décrit la prochaine évolution ; il ne vaut pas annonce de fonctionnalités déjà disponibles.
