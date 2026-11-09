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
10. **Palette et logo.** Le 8 novembre, Antoine fournit l’identité déjà refaite : logo « repère » (une courbe qui se pose sur un point sarcelle), icône d’app claire et sombre, mot-symbole, et cinq couleurs : Encre `#141414`, Graphite `#474747`, Papier `#FAFAFA`, Brume `#E3E5E2`, Sarcelle profonde `#1F6F73`. Elle remplace les trois palettes et les cinq logos proposés dans le canevas. Cette palette devient la valeur par défaut ; les six thèmes restent et les choix enregistrés sont conservés. Le nouveau logo remplace Palier — Référence dans l’app, l’icône, le DMG et le kit de marque.

## Critères observables

- Un clic sur la cloche d’un repère suivi active la surveillance. Après une séance à plus de 2× l’habituel, une notification groupée nomme le repère, sa variation et le multiple.
- Une variation déjà signalée ne déclenche jamais de seconde notification, y compris après une révision ou une relance.
- Les anciennes préférences se relisent sans perte. Les nouveaux champs sont optionnels.
- Focus affiche « Pourquoi ce mouvement ? » avec des faits datés et leurs liens. La synthèse n’affiche que des phrases validées.
- Le brief part à l’heure choisie avec la veille, les faits, l’agenda et les seuils proches.
- Aucune marge, aucun rayon, aucune taille et aucune durée hors des jetons du design system.
- `./scripts/check.sh` et `build-app.sh` passent en CI macOS.

## Étapes

Chaque étape se termine par `python3 scripts/guardrails.py`, les tests Python, un commit et un push. Le 8 novembre, Antoine demande d’avancer sans attendre la CI : la compilation et les tests Swift se vérifient à sa passe finale.

- [x] 1. Canevas v2 : trois palettes, cinq logos, trois alternatives de période, écrans réalignés avec la palette recommandée.
- [x] 2. Jetons du design system (espace, rayons, élévation, rôles typographiques, mouvement), palette d’Antoine par défaut, garde-fou typographique, tests de préférences.
- [x] 2b. Logo « repère » : fichiers source dans `Resources/Brand/`, géométrie unique dans `SignalPath.swift`, icône d’app (`scripts/render-icon.swift`), barre des menus, signature, DMG.
- [x] 3a. Alignement : Workspace et sidebar.
- [x] 3b. Alignement : Overview et Focus.
- [x] 3c. Alignement : bandeau et signature.
- [x] 3d. Alignement : Favoris et Alertes.
- [x] 3e. Alignement : Explorer.
- [x] 3f. Alignement : Réglages et accueil.
- [x] 4. Période partagée et persistée, onglets du hub, bandeau sans rail.
- [x] 5. Cœur : mouvement inhabituel, sensibilité, tests.
- [x] 6. Actualisation après clôture, tests de `RefreshPolicy`.
- [x] 7. App : cloche, permission au premier clic, notification groupée, vue Alertes, réglage de sensibilité.
- [x] 8. Source FRED : client, clé, Réglages, suggestions (VIXCLS, DGS10, DTWEXBGS), tests.
- [x] 9. Lecteur XML partagé, flux Fed et BCE, tests sur fichiers d’exemple.
- [x] 10. Titres GDELT et Alpha Vantage News, tests.
- [x] 11. Contexte du jour et inspecteur « Faits ».
- [x] 12. Synthèse : garde-fou testé, deux rédacteurs, Réglages, onglet « Synthèse ».
- [x] 13. Brief du matin : composition, programmation, notification, rubrique.
- [x] 14. Documentation, état Notion, description et checklist de la PR.

Le site (`site/dist/`, kit de marque et favicon) suivra dans un chantier séparé.

## Preuves

- Étape 1 (8 novembre) : page « Refonte » du [canevas](https://claude.ai/artifact/SA5fmyp8tMwNTA1CQ3g5KK). Trois palettes et cinq logos, remplacés le 8 novembre par l’identité fournie par Antoine ; trois alternatives de période (onglets retenus), Focus, Alertes, Réglages, bandeau sans rail et brief réalignés. Rendu non contrôlé visuellement par l’agent.
- Étape 2 (8 novembre, commit `082f8ae`) : `Spacing`, `Radius`, `TypeRole` et `Motion` dans `DesignSystem` ; `Theme` lit ces jetons (rangées 10, cartes et surfaces 16, groupes 24, page 32, filet 1, élévations 1 à 3) ; `PressStyle` suit Mouvement 1.1 ; palette « sema » par défaut des nouveaux profils, test `newProfileStartsWithTheBrandPaletteAndKeepsSavedChoices`. Garde-fous, 42 tests Python et [CI macOS](https://github.com/antoineberjoan/sema/actions/runs/42429502672) au vert. `.system(size:)` reste toléré hors `TypeRole` jusqu’à la fin de l’étape 3.
- Étape 2b (8 novembre, commit `62107c2`) : logo repère dans `SignalPath` (géométrie unique, carré de 320) et `SignalDot` (point et écart) ; `Symbol`, signature du bandeau, accueil, `render-icon.swift` (icône d’après `sema-app-icon.svg`) et fond du DMG. Fichiers d’Antoine dans `Resources/Brand/`. Garde-fous au vert ; rendu non vérifié.
- Étape 3 (8 novembre) : styles natifs remplacés par les rôles de Typographie 1.1 dans toute l’app ; écarts, rayons et durées ramenés aux jetons dossier par dossier (sidebar sur un bord commun de 16 pt, Focus en rôle hero, badges en rôle tag, bandeau 200/120 ms, signature sous 900 ms, accueil et réglages). Le garde-fou refuse désormais toute taille de texte écrite en chiffres hors de `TypeRole.swift` (test `test_text_size_lives_in_type_roles`). Garde-fous et 42 tests Python au vert ; un contrôle local des symboles `Self.x` et des jetons ne signale rien. Compilation non vérifiée ici.
- Étape 4 (8 novembre) : `periodID` optionnel dans `AppPreferences` ; `AppStore.period` lu depuis les préférences, `setPeriod` et `period(for:)` (une série trop courte affiche tout, sans changer le choix) ; `PeriodTabs` « 3M 1A 3A 5A Max » dans Focus ; le bandeau supprime le rail et `RibbonPeriodPicker`, suit le hub, garde l’accès aux réglages sur la signature. Test `sharedPeriodPersistsAndOlderFilesKeepOneYear`.
- Étape 5 (8 novembre) : `UnusualMove` (variation de la séance divisée par l’écart-type des 20 variations précédentes, en points pour les taux, en % sinon ; refus si historique court, convention inconnue ou écart-type nul), `MoveSensitivity` (3×, 2×, 1,5×), condition `unusualMove`, `AlertRule.unusualMove`, `AlertEvent.ratio`, `moveSensitivityID` optionnel. `AlertEvaluator.newEvents` réutilise le point de contrôle. Quatre tests dans `UnusualMoveTests`.
- Étape 6 (8 novembre) : `RefreshPolicy` connaît les clôtures des jours ouvrés (Paris 17 h 50, New York 16 h 20, heure locale de chaque place) ; une série surveillée devient à jour dès qu’une clôture est passée depuis sa synchronisation, et le minuteur se cale sur la prochaine clôture. `AppStore.followsCloses` relie ce rythme aux seules séries surveillées. Tests sur le jeudi 5 novembre et le week-end. Limite : si le fournisseur publie la clôture en retard, la séance est vue au contrôle suivant.
- Étape 7 (8 novembre) : `WatchButton` (cloche « Me prévenir », clic = surveillance, menu « Ajouter un seuil… ») dans Focus, les aperçus et la vue Alertes ; entrée équivalente dans le menu contextuel de la sidebar. Le premier clic demande l’autorisation des notifications. « Surveiller vos N favoris ? » active tout en un clic. `evaluateAlerts` évalue seuils et mouvements et envoie une seule notification groupée (fil `sema.alerts`), une ligne par repère. `MoveBadge` colore l’écart en cinq zones de la sarcelle. Réglages → Général → Alertes : notifications et sensibilité (Discrète, Normale, Attentive) avec la fréquence théorique.
- Étape 8 (8 novembre) : `StatisticalSource.fred` (clé obligatoire, inactive au départ). Catalogue = publications FRED, structure = séries de la publication par popularité, observations + fiche de la série ; unités converties (Percent → PC en points, Index → IX en %, milliards de dollars → USD × 10^9), valeurs manquantes « . » ignorées. La clé n’entre dans l’URL qu’à l’envoi (`api_key`), jamais dans les requêtes construites ; refus 400 → « clé refusée ». Clé dans le Trousseau, validée avant enregistrement, section FRED dans Réglages → Sources. Suggestions : VIXCLS, DGS10, DGS2, DTWEXBGS, DEXUSEU (identifiants de publication à vérifier avec une vraie clé). Quatre tests dans `FREDClientTests`.
- Étape 9 (8 novembre) : le lecteur XML privé du décodeur SDMX devient `XMLTree`, partagé (entités refusées, CDATA lu). `PressReleaseClient` lit les flux RSS ou Atom de la Fed et de la BCE (`CentralBankFeed`), garde les entrées datées avec un lien https et les trie. Interrupteurs dans Réglages → Sources, via `disabledSourceIDs`. Trois tests dans `PressReleaseClientTests`. Adresses des flux non appelées ici.
- Étape 10 (8 novembre) : `Headline`, `HeadlineSource` (GDELT par défaut, Alpha Vantage News, aucune) et `headlineSourceID` optionnel. `GDELTClient` interroge la fenêtre de la séance en anglais, sans clé ; `MarketDataClient.news` réutilise la clé, l’espacement et les erreurs d’Alpha Vantage. Liens https seulement. Choix dans Réglages → Sources. Trois tests dans `HeadlineTests`. Conditions d’usage de GDELT non vérifiées.
- Étape 11 (8 novembre) : `DayContext` (repères liés via `PeerMove`, calendrier FRED `releases/dates`, communiqués, titres, parties indisponibles nommées), fenêtre UTC de la séance. `AppStore.dayContext` charge chaque partie indépendamment et garde le résultat en mémoire pour la session. Focus : bouton « Pourquoi ? » et inspecteur natif `MoveContextView`. Trois tests dans `DayContextTests`.
- Étape 12 (8 novembre) : `ContextFact` numérote les faits de la séance (mouvement du repère, repères liés, agenda, communiqués, titres). `SummaryCheck` ne garde une phrase que si elle cite des faits existants, si chaque chiffre s’y retrouve (arrondi permis, date de séance exclue, chiffres des noms tolérés), si ses mots de hausse ou de baisse correspondent au sens d’un fait cité et si elle n’affirme aucune cause ; trois phrases au plus, phrases masquées comptées. `SummaryPrompt` est commun aux deux rédacteurs. `ClaudeClient` : un appel Messages en JSON contraint, modèle `claude-opus-5-5`, effort bas, repli serveur `fallbacks: "default"`, clé dans l’en-tête seulement, validée par la liste des modèles. `AppleSummaryWriter` : `FoundationModels` derrière `canImport` et macOS 26. `summaryWriterID` optionnel (désactivé par défaut) ; Réglages → Sources → Synthèse rédigée ; onglets « Faits / Synthèse » dans l’inspecteur, rédaction à la demande, résultat en mémoire par séance et rédacteur. Dix tests dans `SummaryTests`. Non vérifié : compilation Swift, appel réel à Claude, chemin Apple Intelligence, adresse de création de clé Anthropic.
- Étape 13 (8 novembre) : `MorningBrief` réunit les mouvements inhabituels de la dernière séance (4 jours au plus, sensibilité choisie), les seuils en niveau proches et non franchis (2 % du seuil, 0,10 point pour les taux), l’agenda FRED du jour et les communiqués des dernières 24 h. `BriefPreferences` (désactivé, 8 h 00, jours ouvrés) dit quand le brief est dû : une fois par jour après l’heure, au réveil si le Mac dormait. `RefreshController` l’envoie après l’actualisation et se réveille à l’heure du brief ; un changement de réglage replanifie le minuteur. Notification groupée « Brief du matin », rubrique Brief (⌘5) avec proposition d’activation, Réglages → Général → Brief du matin. Quatre tests dans `MorningBriefTests`. Non vérifié : compilation, rendu, délivrance réelle à 8 h.
- Étape 14 (8 novembre) : `PRODUCT.md` (promesse, bandeau sans rail, onglets, cloche, contexte, synthèse, brief, ⌘5), `ARCHITECTURE.md` (types du cœur et de l’app, champs optionnels, notification groupée), `IDENTITY.md` (Typographie, Espace et forme, Mouvement 1.1, palette sema, logo repère), `DATA-SOURCES.md` (sources du contexte), `PUBLIC-CATALOGUES.md` (FRED connecté), `GLOSSARY.md` (termes du chantier). État reporté dans Notion Produit. Description et checklist dans la PR nº 15. Sur demande d’Antoine, la CI n’est plus attendue : compilation et rendu se vérifient à sa passe.
- Correction après échec de la CI (8 novembre) : le journal montre une compilation réussie et 3 tests périmés par l’ajout de FRED (source inactive par défaut ; 5 références au lieu de 20). Tests mis à jour, règles inchangées : liste des sources inactives avec `fred`, boucle des 20 références hors FRED, contrat FRED à 5 références. Non relancé en CI.
- Écarts comblés (9 novembre) : clic sur une notification (`NotificationTarget` dans les informations de la notification, `AppDelegate` ouvre le repère et son inspecteur, la rubrique Alertes ou le Brief) ; titres de la séance dans le brief (`MorningBrief.headlines`, 3 au plus, test ajouté) ; cloche dans le menu contextuel des cartes du bandeau. Non vérifié : le menu contextuel dans le panneau non activant du bandeau, et le clic de notification sur un vrai Mac.
- Décisions d’Antoine du 9 novembre : cartes du bandeau en variante B, agenda dans le Brief, site selon le système (maquettes sur le canevas). Faits : `RibbonCard` refaite (source et unité sous le nom, badge de variation de la période, date et valeur, puce de séance inhabituelle, courbe pleine largeur avec lecture au survol) ; `DayAgenda` et `AgendaItem` dans le cœur (ordre des lignes, trois d’abord, semaine ouvrée, quatre tests) ; `AgendaView` dans Brief avec chargement par jour (`AppStore+Agenda`). Les sections « Agenda du jour », « Banques centrales » et « Titres de la séance » du Brief sont remplacées par l’agenda. Non vérifié : compilation, rendu, `chartXSelection` dans le panneau du bandeau, requêtes GDELT à chaque clic de jour. Hors décision : carte Agenda du bandeau (maquette à refaire), site, « app plus intuitive ».

## Limites connues

- Ce conteneur est sous Linux : aucun rendu natif n’y est vérifié. La compilation et les tests Swift se vérifient sur le Mac d’Antoine.
- La CI `macos-15` ne compile probablement pas `FoundationModels` : le chemin Apple Intelligence se compile et se teste sur le Mac d’Antoine.
- Les appels réels FRED, GDELT, Alpha Vantage News et Claude demandent les clés d’Antoine.
- Aucune source quotidienne gratuite et officielle n’a été trouvée pour le CAC 40 et l’Euro Stoxx 50.

## Prochaine action

Passe de contrôle d’Antoine sur son Mac (checklist dans la PR nº 15), puis son accord pour fusionner.
