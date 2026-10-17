# Recherche naturelle dans Explorer

Statut : comparaison terminée, intégration non validée et non activée, 17 octobre 2026, branche `codex/ribbon-signature`.

Source : Antoine demande dans le chat du 17 octobre la recherche naturelle Apple Intelligence dans le champ existant d’Explorer, avec recherche classique sur les Mac non compatibles. Il précise ensuite que la fonction doit être précise, fonctionnelle et déterministe ; sinon elle ne doit pas être proposée à moitié aboutie. Décision dans [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296).

## Critères observables

- Même champ, effacement et navigation clavier ; aucune rubrique IA ni nouvel écran.
- L’interprétation Apple locale doit conduire à des résultats pertinents exclusivement issus des catalogues, avec aperçu et ajout existants. Aucun code de série, valeur ou calcul n’est généré. Le protocole peut sélectionner des références réelles plutôt que reformuler la demande.
- Les accès exacts et filtres explicites restent prioritaires. Une saisie plus récente, une fermeture ou un changement de source empêche une ancienne réponse de modifier les résultats.
- Recherche classique utilisable sur macOS 14+, lorsque Apple Intelligence est indisponible et en cas d’erreur du modèle. Aucun fournisseur distant ni dépendance ajoutée.
- Vérifier la disponibilité réelle du modèle, la précision et la répétabilité sur un corpus figé avant intégration. Une approche retenue devrait ensuite passer le parcours natif, l’annulation, les changements de source et le retour à la recherche classique.

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

Deux résultats conformes sur six essais, dont seulement une des trois demandes économiques distinctes. Les trois répétitions d’inflation sont identiques ; cela prouve uniquement une stabilité observée sur cet environnement, pas une garantie entre versions du modèle ou machines. Le script au commit `4e0bcdb` reproduit ces six résultats, avec un code de sortie 1 et une latence de 1,39 à 6,00 s par essai sur son passage initial. Ce contrôle élémentaire suffit à rejeter l’activation ; il ne constitue pas une évaluation générale des capacités d’Apple Intelligence.

## État actuel

L’intégration expérimentale, ses états et ses tests spécifiques ont été retirés de `Sources` et `Tests`. Explorer conserve exactement sa recherche classique et ses catalogues. Aucun réglage IA caché, aucune dépendance de production, aucune migration, fusion main ou publication. Le script d’évaluation reste séparé de l’app dans `scripts/evaluate-natural-search.swift` ; il compare désormais une sélection de vrais identifiants et ne lit ni préférence, ni clé, ni donnée personnelle.

Après retrait du prototype, le bundle debug compile, sa signature stricte est valide et il ne lie plus Foundation Models. Les 86 tests du cœur existant réussissent localement avec les chemins des frameworks de tests des Command Line Tools ; aucune règle du dépôt n’a été affaiblie. Le prototype avait aussi passé les contrôles de structure, les 17 tests Python et 90 tests Swift : ces tests mécaniques n’ont pas été considérés comme une preuve de pertinence du modèle.

## Reproduire sur un Mac compatible

Avec le cœur compilé en debug, depuis la racine du dépôt :

```sh
xcrun swiftc -parse-as-library -swift-version 6 -module-cache-path .build/ModuleCache -I .build/arm64-apple-macosx/debug/Modules scripts/evaluate-natural-search.swift .build/arm64-apple-macosx/debug/MarketCore.build/*.o -o .build/evaluate-natural-search
.build/evaluate-natural-search
```

Le script interroge le catalogue public Insee une fois, trie ses jeux par identifiant et conserve le même instantané pour seize essais, dont trois répétitions. Les codes attendus servent uniquement au contrôle, jamais aux instructions du modèle. Une sortie n’est conforme que si elle contient au moins un jeu attendu, sans jeu hors sujet ; pour les demandes hors périmètre, elle doit être vide. Ce contrôle ne mesure ni le rappel exhaustif ni l’actualité des séries à l’intérieur d’un jeu.

Code de sortie 1 si les attentes ou les répétitions échouent, 2 si le modèle est indisponible ou si le catalogue a changé. SDK Foundation Models de macOS 26 requis. Aucun réglage ni installation ; un catalogue figé, des sessions neuves et `greedy` permettent de comparer les essais sans prétendre garantir le résultat entre versions du modèle.

## Comparaisons complémentaires

Antoine demande ensuite de ne pas généraliser l’échec du prototype à toutes les capacités d’Apple Intelligence. La disponibilité et le français sont revérifiés : `available`, `supportsFrench: true`. Les inférences fonctionnent sur le Mac ; le refus du premier prototype portait sur la qualité de son architecture.

| Approche testée | Observation utile |
| --- | --- |
| `contentTagging`, mots contraints puis consigne de tags simple | Les questions reçoivent des tags tels que « information retrieval », pas seulement leur sujet économique. La documentation Apple décrit cette limite ; cet usage spécialisé ne remplace pas une interprétation de recherche. |
| Extraction sujet/pays/période avec le modèle général | Inflation correctement isolée, mais ajout de France/2024 sur une demande de loyers qui ne contenait pas ces critères ; chômage parfois transformé en changement. Champs structurés ne signifie pas contenu exact. |
| `NLEmbedding`, titres et phrases françaises | Modèles natifs présents, indexation de 244 titres en 1,19 s. Les mots courts peuvent fonctionner ; les phrases complètes classent parfois le revenu ou la consommation avant le bon concept. C’est une API Natural Language distincte de Foundation Models. |
| Sélection de vrais identifiants, lots de 50 titres, schéma fermé | Retrouve `CPI` pour l’inflation et le coût de la vie, et des jeux de chômage pour « les gens sans emploi ». Des paraphrases sur naissances ou défaillances restent vides ; dette et richesse produite peuvent contenir de nombreux jeux hors sujet. |
| Recherche littérale simplifiée avant sélection, puis classement lexical déterministe | Récupère rapidement les correspondances explicites : loyers, chômage, créations, naissances et dette. Ne résout pas les paraphrases absentes des libellés ; sur « sans emploi », un classement lexical peut même éliminer le bon jeu. Aucun code de ce prototype n’est intégré à l’app. |
| Lots de 80 et instruction renforcée | Variante moins bonne sur l’inflation. Le volume du contexte et les instructions changent la qualité. La comparaison modifie les deux facteurs ; elle ne permet pas d’attribuer la régression à un seul. |

Le dernier passage du script conservé obtient **5 essais conformes sur 16**, dont trois répétitions du même cas inflation : `CPI` à chaque fois, sans autre jeu. Le chômage formulé explicitement et la météo hors périmètre sont aussi conformes. Les loyers, la dette et les créations comportent des jeux hors sujet ; les bébés nés cette année ne donnent rien. Les naissances explicites contiennent le bon jeu et un jeu plus général de structure de population, classé non conforme par l’attente stricte. Une recette et une instruction détournant la recherche peuvent aussi produire des jeux économiques. Latence : **3,92 à 7,17 s**. Ce sont les résultats de ce protocole, pas un score général d’Apple Intelligence.

Les variantes antérieures avaient de meilleurs résultats sur certaines phrases : consignes et ponctuation diffèrent du script final. Les répétitions identiques ne prouvent donc pas une robustesse aux reformulations. Les attentes sont volontairement explicites et limitées ; elles ne remplacent pas une revue des cas ambigus ni une évaluation indépendante plus large.

Les identifiants du schéma et une vérification après génération empêchent un jeu inventé ; ils n’empêchent pas de choisir le mauvais jeu réel. La sélection par lots de 50 corrige le cas inflation du premier protocole, mais reste insuffisante sur le corpus élargi. Elle ne valide pas encore les catalogues plus volumineux, les libellés anglais, les filtres géographiques ou l’aperçu de série.

Les principes conservés sont : priorité aux recherches exactes, catalogue et classement déterministes, interprétation locale bornée et contrôlée, aucun effet sur une valeur ou un calcul. Le prochain essai utile devra améliorer les échecs explicites sur un corpus séparé puis vérifier le parcours complet ; répéter des exemples réussis ou mémoriser la première sortie ne suffirait pas. Aucune conclusion « Apple Intelligence ne fonctionne pas » ni « toutes les approches ont été testées » n’est justifiée par ces essais.

## Références Apple

- [Foundation Models](https://developer.apple.com/foundation-models-framework/) : accès au modèle local.
- [Prompting an on-device foundation model](https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model) : consignes, contexte et génération structurée.
- [Content tags](https://developer.apple.com/documentation/foundationmodels/categorizing-and-organizing-data-with-content-tags) : usage spécialisé et distinction entre sujet d’une question et type de question.
- [NLEmbedding](https://developer.apple.com/documentation/naturallanguage/nlembedding) : API sémantique Natural Language distincte, également testée.
