# Alertes de marché, contexte du jour et refonte visuelle

Statut : en cours depuis le 8 novembre 2026, branche `claude/market-alerts-redesign`, PR brouillon. Aucune fusion vers `main` ni publication sans accord d’Antoine.

Source : le 5 novembre 2026, Antoine apprend la chute des marchés (S&P 500 −4,4 %, Nasdaq −5,5 %, VIX +70 %) par un post sur X. Dans le chat des 7 et 8 novembre, il demande d’être prévenu vite et de comprendre pourquoi. Il valide la maquette ([canevas](https://claude.ai/artifact/SA5fmyp8tMwNTA1CQ3g5KK)) et le plan, puis demande tout le périmètre ci-dessous. Arbitrages reportés dans [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296) et [Marque](https://app.notion.com/p/3fbd18bb0dea818fa7f4fc7483c767b3).

## Arbitrages d’Antoine (8 novembre)

1. **Mouvement inhabituel.** Alerte sur les repères suivis quand la variation d’une séance dépasse un multiple de la variation habituelle (écart-type des 20 variations précédentes). Une seule notification regroupe les repères d’une même vérification.
2. **Alertes simples.** Un clic sur une cloche active la surveillance avec des réglages par défaut : 2× l’habituel, hausse et baisse. Une sensibilité globale (Discrète 3×, Normale 2×, Attentive 1,5×) remplace tout formulaire. Les seuils existants restent accessibles depuis la même cloche.
3. **Rythme.** Les repères de marché surveillés sont actualisés après chaque clôture (New York, Paris). Cette règle remplace l’intervalle de 24 h pour eux seulement.
4. **Contexte du jour.** Faits datés avec leurs liens : repères liés (calcul local), publications FRED, communiqués Fed et BCE, titres (GDELT ou Alpha Vantage News).
5. **Synthèse rédigée.** Trois phrases reliées à leurs sources, désactivée par défaut. Le rédacteur se choisit dans Réglages : Apple Intelligence sur le Mac ou API Claude avec une clé personnelle. Un garde-fou masque toute phrase dont un nombre ou un sens ne correspond pas aux faits collectés. « Comprendre » reste déterministe.
6. **Brief du matin.** Notification à l’heure choisie (8 h 00, jours ouvrés), ou au réveil. Elle ouvre la rubrique Brief.
7. **Sources.** FRED avec une clé gratuite. La clé passe dans l’URL (`api_key`), seule méthode offerte : même exception qu’Alpha Vantage.
8. **Période.** Onglets texte dans le hub. Le bandeau perd son rail et suit la période du hub. La maquette présente les alternatives.
9. **Design.** Les spécifications *Espace et forme 1.1*, *Mouvement 1.1* et *Typographie 1.1* du 5 novembre remplacent rayons, espacements, tailles et durées. `.system(size:)` est autorisé seulement dans le fichier des rôles typographiques.
10. **Palette et logo.** Une nouvelle palette devient la valeur par défaut ; les six thèmes restent et les choix enregistrés sont conservés. Cinq logos sont proposés ; le tracé actuel reste jusqu’au choix d’Antoine.

## Critères observables

- Un clic sur la cloche d’un repère suivi active la surveillance. Après une séance à plus de 2× l’habituel, une notification groupée nomme le repère, sa variation et le multiple.
- Une variation déjà signalée ne déclenche jamais de seconde notification, y compris après une révision ou une relance.
- Les anciennes préférences se relisent sans perte. Les nouveaux champs sont optionnels.
- Focus affiche « Pourquoi ce mouvement ? » avec des faits datés et leurs liens. La synthèse n’affiche que des phrases validées.
- Le brief part à l’heure choisie avec la veille, les faits, l’agenda et les seuils proches.
- Aucune marge, aucun rayon, aucune taille et aucune durée hors des jetons du design system.
- `./scripts/check.sh` et `build-app.sh` passent en CI macOS.

## Étapes

Chaque étape se termine par `python3 scripts/guardrails.py`, les tests Python, un commit, un push et une CI verte.

- [x] 1. Canevas v2 : trois palettes, cinq logos, trois alternatives de période, écrans réalignés avec la palette recommandée.
- [ ] 2. Jetons du design system (espace, rayons, élévation, rôles typographiques, mouvement), nouvelle palette par défaut, garde-fou typographique, tests de préférences.
- [ ] 3a. Alignement : Workspace et sidebar.
- [ ] 3b. Alignement : Overview et Focus.
- [ ] 3c. Alignement : bandeau et signature.
- [ ] 3d. Alignement : Favoris et Alertes.
- [ ] 3e. Alignement : Explorer.
- [ ] 3f. Alignement : Réglages et accueil.
- [ ] 4. Période partagée et persistée, onglets du hub, bandeau sans rail.
- [ ] 5. Cœur : mouvement inhabituel, sensibilité, tests.
- [ ] 6. Actualisation après clôture, tests de `RefreshPolicy`.
- [ ] 7. App : cloche, permission au premier clic, notification groupée, vue Alertes, réglage de sensibilité.
- [ ] 8. Source FRED : client, clé, Réglages, suggestions (VIXCLS, DGS10, DTWEXBGS), tests.
- [ ] 9. Lecteur XML partagé, flux Fed et BCE, tests sur fichiers d’exemple.
- [ ] 10. Titres GDELT et Alpha Vantage News, tests.
- [ ] 11. Contexte du jour et inspecteur « Faits ».
- [ ] 12. Synthèse : garde-fou testé, deux rédacteurs, Réglages, onglet « Synthèse ».
- [ ] 13. Brief du matin : composition, programmation, notification, rubrique.
- [ ] 14. Documentation, état Notion, description et checklist de la PR.

Après la boucle : Antoine choisit le logo, puis la géométrie retenue remplace l’actuelle partout (`SignalPath.swift`, `scripts/render-icon.swift`, `Resources/Brand/`, `Resources/DMG/`, `site/dist/`). Le site suivra dans un chantier séparé.

## Preuves

- Étape 1 (8 novembre) : page « Refonte » du [canevas](https://claude.ai/artifact/SA5fmyp8tMwNTA1CQ3g5KK). Trois palettes (Encre & Laiton recommandée, Lagune, Nuit d’hiver), cinq logos (Palier, Sigma, Borne, Horizon, Écart), trois alternatives de période (onglets retenus), Focus, Alertes, Réglages, bandeau sans rail et brief réalignés. Rendu non contrôlé visuellement par l’agent.

## Limites connues

- Ce conteneur est sous Linux : aucun rendu natif n’y est vérifié. La compilation et les tests Swift passent par la CI macOS.
- La CI `macos-15` ne compile probablement pas `FoundationModels` : le chemin Apple Intelligence se compile et se teste sur le Mac d’Antoine.
- Les appels réels FRED, GDELT, Alpha Vantage News et Claude demandent les clés d’Antoine.
- Aucune source quotidienne gratuite et officielle n’a été trouvée pour le CAC 40 et l’Euro Stoxx 50.

## Prochaine action

Étape 2 : jetons du design system et palette Encre & Laiton.
