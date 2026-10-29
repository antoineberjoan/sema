# Suggestions de départ par source

## Source de la demande

Demande explicite d’Antoine dans la conversation Homebrew Releases : remplacer les exemples peu reconnaissables par environ vingt séries de départ pertinentes pour chaque fournisseur, y compris les sources statistiques publiques, sans réduire leurs catalogues complets. La page Produit canonique n’est pas encore accessible ; la demande de connexion Notion est en attente. Ce plan décrit sa réalisation, sans constituer une priorité produit de remplacement.

## Résultat attendu

Explorer affiche « Pour commencer » avant le catalogue complet. Les actions proposées sont des références exactes de chaque fournisseur et n’ajoutent pas automatiquement une série. Un clic reprend le parcours de découverte et d’aperçu existant ; le titre officiel et les métadonnées proviennent du catalogue actif. Une recherche saisie masque les suggestions sans modifier les résultats du catalogue.

## Couverture

Les deux fournisseurs de cours de marché reçoivent dix-huit actions américaines reconnues communes, plus deux références adaptées à leur catalogue réel : SPY/QQQ pour Alpha Vantage ; chez Twelve Data, le S&P 500 et le CAC 40 (FCHI) s’ils existent comme indices dans le catalogue autorisé, avec SPY/QQQ en repli. Les sept sources statistiques publiques reçoivent vingt références chacune : indices de prix Insee, changes BCE, inflation/chômage Eurostat, taux directeurs BRI, IPC OCDE, mesures de taux New York Fed et indicateurs Banque mondiale pour la France. Le catalogue complet et la recherche restent ouverts.

Les identifiants candidats sont confrontés aux données ou métadonnées publiques officielles déjà consultées. Les clés SDMX sont complètes et incluent leur ordre dimensionnel ; le code d’indicateur et le pays sont conservés pour la Banque mondiale ; les types et mesures Fed restent distincts. Les suggestions ne remplacent pas les métadonnées officielles, ne garantissent pas un historique disponible et sont masquées si leur jeu n’existe plus dans le catalogue actuel.

## Étapes et preuves

- [x] Maintenir dix-huit actions connues communes, puis préférer les indices directs S&P 500/CAC 40 chez Twelve Data seulement s’ils sont réellement exposés comme indices autorisés ; sinon utiliser SPY/QQQ.
- [x] Définir vingt références exactes et testables pour chacune des sept sources statistiques publiques.
- [x] Ajouter « Pour commencer » dans Explorer sans toucher à l’ajout automatique, aux préférences existantes ou au chemin de recherche.
- [x] Garde-fous du dépôt et 42 tests Python réussis localement ; les journaux locaux et masques du sandbox ont été exclus temporairement du seul contrôle de structure.
- [ ] Confirmer la compilation et les tests Swift sur CI macOS ; Swift n’est pas installé sur le Cloud Linux.
- [ ] Vérifier le parcours dans l’app native ; la capture utilisateur du catalogue marché sert de référence de contenu, pas de preuve du nouveau rendu.
- [ ] Mettre à jour la page Produit lorsque l’accès Notion sera disponible.

## Publication

La PR #14 couvre la sélection des fournisseurs de cours de marché ; sa fusion est demandée séparément après ses deux contrôles verts. Les indices directs Twelve Data et les suggestions des sept sources statistiques suivent dans une PR distincte depuis `reason/popular-market-starters`, à vérifier sur CI macOS avant fusion. Le rendu natif n’a pas encore été capturé sur macOS et la page Produit Notion reste inaccessible.
