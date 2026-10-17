# Recherche naturelle dans Explorer

Statut : évaluation terminée, activation rejetée, 17 octobre 2026, branche `codex/ribbon-signature`.

Source : Antoine demande dans le chat du 17 octobre la recherche naturelle Apple Intelligence dans le champ existant d’Explorer, avec recherche classique sur les Mac non compatibles. Il précise ensuite que la fonction doit être précise, fonctionnelle et déterministe ; sinon elle ne doit pas être proposée à moitié aboutie. Décision dans [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296).

## Critères observables

- Même champ, effacement et navigation clavier ; aucune rubrique IA ni nouvel écran.
- Le modèle Apple local reformule la demande en termes de recherche. Les résultats viennent exclusivement des catalogues, avec aperçu et ajout existants. Aucun code de série, valeur ou calcul n’est généré.
- Les accès exacts et filtres explicites restent prioritaires. Une saisie plus récente, une fermeture ou un changement de source empêche une ancienne réponse de modifier les résultats.
- Recherche classique utilisable sur macOS 14+, lorsque Apple Intelligence est indisponible et en cas d’erreur du modèle. Aucun fournisseur distant ni dépendance ajoutée.
- Vérifier le modèle effectivement disponible et une reformulation sur le Mac d’Antoine, les requêtes Webstat échappées, le filtrage public, la compilation et le parcours natif isolé.

## Résultat observé

Le MacBook Air M2 avec 8 Go et macOS 26.6.2 renvoie `available` et prend en charge le français via `SystemLanguageModel`. Des inférences locales ont effectivement fonctionné, sans clé, fournisseur distant ni adhésion Apple Developer. Cette compatibilité matérielle ne prouve pas la qualité de la recherche.

La reformulation libre, puis une sortie structurée français/anglais, ne retrouvaient pas correctement l’inflation dans Insee, ou élargissaient à tous les prix et à la consommation. Une deuxième approche contraignait les mots générés aux 371 termes présents dans les titres du catalogue Insee. L’inclusion automatique du schéma dépassait la fenêtre locale : 5 469 tokens pour 4 096 disponibles. Un schéma contraint avec vocabulaire compact séparé a résolu ce dépassement, mais pas les erreurs de sens.

Six essais avec sessions neuves, échantillonnage `greedy`, instructions et catalogue figés ont donné :

| Demande | Répétitions | Sortie et résultat observés |
| --- | --- | --- |
| Inflation en France sur cinq ans | 3 | `france` répété quatre fois ; trois jeux sur commerce extérieur, tourisme et musées. Résultat stable mais faux. |
| Évolution des loyers | 1 | `loyer loyers loyer loyer` ; `INDICES_LOYERS` et `SERIES_LOYERS`, pertinents. |
| Taux de chômage en France | 1 | `chomage france` ; aucun jeu, malgré des jeux de chômage publiés. |
| Météo de demain | 1 | Termes hors sujet ; aucun résultat, comme attendu pour une recherche hors périmètre. |

Deux résultats conformes sur six essais, dont seulement une des trois demandes économiques distinctes. Les trois répétitions d’inflation sont identiques ; cela prouve uniquement une stabilité observée sur cet environnement, pas une garantie entre versions du modèle ou machines. Le script conservé reproduit ces six résultats, avec un code de sortie 1 et une latence de 1,39 à 6,00 s par essai sur son dernier passage. Ce contrôle élémentaire suffit à rejeter l’activation ; il ne constitue pas une évaluation générale des capacités d’Apple Intelligence.

## État livré

L’intégration expérimentale, ses états et ses tests spécifiques ont été retirés de `Sources` et `Tests`. Explorer conserve exactement sa recherche classique et ses catalogues. Aucun réglage IA caché, aucune dépendance de production, aucune migration, fusion main ou publication. Le script d’évaluation reste séparé de l’app dans `scripts/evaluate-natural-search.swift` ; il ne lit ni préférence, ni clé, ni donnée personnelle.

Après retrait du prototype, le bundle debug compile, sa signature stricte est valide et il ne lie plus Foundation Models. Les 86 tests du cœur existant réussissent localement avec les chemins des frameworks de tests des Command Line Tools ; aucune règle du dépôt n’a été affaiblie. Le prototype avait aussi passé les contrôles de structure, les 17 tests Python et 90 tests Swift : ces tests mécaniques n’ont pas été considérés comme une preuve de pertinence du modèle.

## Reproduire sur un Mac compatible

Avec le cœur compilé en debug, depuis la racine du dépôt :

```sh
xcrun swiftc -parse-as-library -swift-version 6 -module-cache-path .build/ModuleCache -I .build/arm64-apple-macosx/debug/Modules scripts/evaluate-natural-search.swift .build/arm64-apple-macosx/debug/MarketCore.build/*.o -o .build/evaluate-natural-search
.build/evaluate-natural-search
```

Le script interroge le catalogue public Insee une fois, conserve le même vocabulaire pour tous les essais et n’installe rien. Code de sortie 1 si les attentes élémentaires échouent, 2 si le modèle n’est pas disponible. Il exige le SDK Foundation Models de macOS 26. Un succès futur nécessiterait encore un corpus plus large, des requêtes ambiguës et adversariales, des catalogues multilingues et une validation native avant toute activation.

Pour une future tentative, le moteur de recherche doit rester déterministe sur un plan de recherche validé : libellés et codes officiels, filtres explicites, classement stable. Une sortie syntaxiquement valide, un réglage `greedy` ou un cache de la première réponse ne prouvent pas que l’interprétation économique est correcte. Aucune nouvelle intégration n’est prévue sans preuve supérieure à ce protocole.
