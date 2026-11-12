# Les contrats de comportement qui comptent ont chacun un test

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Un contrat de comportement s'écrit avec sa valeur exacte. Une règle qui compte a un test : sans test, personne ne voit qu'on la casse. Quatre contrats sont dans ce cas ou doivent être vérifiés.

## Décision

Chaque contrat ci-dessous a un test qui nomme sa valeur. Un contrat déjà couvert le dit.

| Contrat | Valeur exacte | Où il vit | Test |
| --- | --- | --- | --- |
| Pagination de la recherche Webstat | Pages de 50 résultats. L'API refuse un décalage au-delà de 10 000 : le dernier décalage permis est 9 950. À partir de 9 950, un export réduit à sept champs (`series_key`, `dataset_id`, `title_fr`, `freq`, `unit`, `unit_mult`, `ref_area`) est chargé une fois par recherche, puis paginé sur place | `WebstatClient.pageSize` et `maximumSearchOffset` ; le choix du seuil est dans `AppStore+Catalogue` | Couvert par `WebstatPagingTests` : pages de 50, dernier décalage 9 950, bascule vers l'export réduit (`WebstatClient.usesSummaryExport`) |
| Fraîcheur d'une série | 24 heures sur la date d'actualisation dans sema. Une date dans le futur oblige à actualiser. Pour une série surveillée, une clôture passée (jours ouvrés de Paris et de New York, à l'heure de chaque place) rend la série due | `RefreshPolicy.interval` | Couvert par `RefreshPolicyTests` (quatre cas, dont l'horloge qui recule et le week-end) |
| Chargement de l'historique ancien | Tranches de 6 années, de la plus récente vers la plus ancienne, avec annulation entre deux. Les périodes récentes sont chargées sur 6 années | `HistoryPeriod.recentYears` ; la boucle est dans `AppStore+History` ; la fenêtre récente dans `WebstatClient` et `PublicDataTransport.historyStart` | Couvert par `HistoryTrancheTests` (tranches de six années, jamais avant le début publié) |
| Garde-fou de la synthèse | Trois phrases au plus. Chaque phrase cite des faits qui existent. Un chiffre peut être arrondi, jamais changé. La date de la séance n'est pas un chiffre. Un mot de hausse ou de baisse doit correspondre au sens d'un fait cité. Toute cause affirmée (« en raison de », « suite à »…) masque la phrase. Le nombre de phrases masquées est dit | `SummaryCheck` | Couvert par `SummaryTests` (chiffres, sens, causes, trois phrases, lecture des nombres français) |

Le seuil de 9 950 et le découpage en tranches sont des calculs de `MarketCore`, testés là. L'orchestration (la boucle de `AppStore+History`, le choix de chemin de `AppStore+Catalogue`) est dans `SemaMac`, qui n'a pas de cible de test : le calcul sorti dans le cœur garde `Package.swift` intact.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Sortir le calcul dans le cœur et le tester là | Un test sans interface, aucune cible nouvelle | Un déplacement de code dans `MarketCore` (niveau rouge) |
| Ajouter une cible de test à `SemaMac` | Tester l'orchestration telle quelle | Une modification de `Package.swift` (niveau rouge) et des essais plus lourds |

## Conséquences

Les tests de comportement protègent les déplacements de code.

## Trace

Les valeurs viennent du code au 2026-11-12 ; les tests sont dans `Tests/MarketCoreTests`.
