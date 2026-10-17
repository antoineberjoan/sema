# Navigation clavier et bandeau Repère

Statut : correction terminée pour revue, vérifiée dans un bundle natif isolé et en CI, 17 octobre 2026. [PR nº 5](https://github.com/antoineberjoan/sema/pull/5), branche `codex/ribbon-signature`.

Source : demandes d’Antoine dans le chat du 17 octobre et pages Notion [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296) et [Marque](https://app.notion.com/p/3fbd18bb0dea818fa7f4fc7483c767b3), consultées et mises à jour le même jour. Le dernier arbitrage précise quatre favoris **en plus** du cartouche signature, toujours visible et teinté par Apparence, des cartes plus carrées, aucun badge « Démo » dans le bandeau et des flèches horizontales identiques aux verticales.

## Contrat retenu

- ↑ / ← sélectionnent le repère précédent ; ↓ / → le suivant, dans l’ordre personnel. Avec ⌘, ces quatre touches pilotent le même sélecteur visuel ; relâcher ⌘ ou Entrée valide, Échap annule. Les champs de saisie et les feuilles conservent leurs contrôles natifs.
- Les raccourcis globaux configurables du bandeau et du hub restent inchangés. Les quatre combinaisons ⌘ + flèche sont réservées à la navigation locale.
- Repère conserve ses cinq périodes : 3 mois, 1 an, 3 ans, 5 ans, Tout. Quatre favoris sont visibles sur écran assez large, en plus du cartouche ; les favoris supplémentaires défilent seuls. Une largeur moindre réduit leur nombre visible.
- Le cartouche signature et « Une idée ou un bug ? » restent hors du défilement horizontal, y compris sans favori. Les positions latérales conservent leur signature fixe et leurs contrôles natifs.
- Cartes horizontales de 208 à 232 pt de large et 216 pt de haut. Le cartouche reprend l’accent approfondi de la palette choisie, dont le gris de Graphite. Aucun badge d’origine ni flèche décorative dans les cartes ; les données fictives restent identifiées dans le détail et par VoiceOver.
- Aucun changement de préférences, de sélection, d’ordre personnel, de source ou d’alerte ; aucun nouvel appel réseau.

## Preuves de cette correction

- Garde-fous et `git diff --check` réussis ; 17 tests Python réussis. La suite Swift locale s’arrête faute du module `Testing` dans les Command Line Tools ; la [CI macOS du commit fonctionnel `7ecff3e`](https://github.com/antoineberjoan/sema/actions/runs/39050587878) a ensuite réussi les tests et la construction du bundle.
- `scripts/build-app.sh` construit le bundle release et sa signature stricte est valide. Le premier appel sandboxé bloquait `iconutil` ; le même script hors sandbox réussit sans changer les contrôles ni les ressources.
- Revue native avec un identifiant de bundle et un dossier de données temporaires distincts : navigation ← / →, ↑ / ↓ et validation de ⌘← / ⌘→ observées. Les événements synthétiques relâchent la combinaison avant la capture : le sélecteur maintenu avec ⌘ reste une limite de cette vérification.
- Quatre favoris plus le cartouche observés simultanément en Graphite puis Lavande, avec le changement effectué dans Apparence. Après défilement, les quatre derniers favoris et la même signature restent visibles. L’outil active parfois le hub après une action sur le panneau non activant ; sa réouverture conserve la position défilée, vérifiée par la capture.
- État sans favori observé en mode clair : accès au choix des favoris et cartouche signature présents.
- Captures conservées dans les artefacts du chat : `sema-ribbon-signature-graphite.png` et `sema-ribbon-signature-lavande.png`. Les préférences habituelles et le dossier principal, occupé par un autre chantier, n’ont pas été modifiés.

## Vérifications restantes et livraison

Position latérale, écran de moindre largeur et options d’accessibilité pris en charge par les chemins existants et la réservation de place, mais non observés dans cette revue. Le contrôle natif s’est interrompu pendant le dernier contrôle d’état ; aucune validation de ces cas n’est déclarée.

Cette correction est sauvegardée séparément pour revue. Aucune nouvelle version distribuée ni fusion vers main n’est déclarée dans ce lot. L’autorisation de la précédente publication concernait la version 0.6.0 ; le téléchargement public reste cette version.

Historique utile : les deux raccourcis globaux, le rail Repère et la persistance ont été vérifiés dans la [CI initiale](https://github.com/antoineberjoan/sema/actions/runs/39019838396), puis intégrés à la version 0.6.0. Les contrôles physiques des raccourcis globaux restent distincts des touches synthétiques locales.

## Ajustement de la lecture du hub — en revue

Demande complémentaire d’Antoine dans le même chat du 17 octobre : rapprocher la variation de la valeur, sous forme de badge teinté par la palette, rendre la création d’alerte visible et expliquer la date. Le badge et son horizon partagent la ligne de la valeur ; `ViewThatFits` permet un repli si la largeur manque. Une variation non calculable reste un état textuel. Le bouton d’alerte est natif et rempli ; les conditions d’unité et de source restent inchangées.

La date sous le graphique devient « Donnée du… », ou la période complète pour une observation couvrant plusieurs jours. Le popover distingue « Actualisé dans sema » avec date et heure de `syncedAt`. Aucun calcul ni cache n’est modifié. Critères : observer le badge à côté de la valeur, changer de période, ouvrir et annuler une alerte, lire les deux dates distinctes, vérifier le mode clair et le repli de la ligne.

Bundle release compilé et signé. Revue native sur le cache BCE EUR/USD réel : badge −3,40 % sur 1 an, bouton rempli ouvrant la bonne série dans l’éditeur, annulation sans enregistrement, donnée du 16 octobre et actualisation du 17 octobre avec heure distincte dans le popover. Capture `sema-detail-badge-dark.png` dans les artefacts du chat. Le badge lit le même horizon que le contrôle de période ; la vérification finale du mode clair et du repli à faible largeur reste à reprendre : le contrôle natif a perdu l’accès après la fermeture des réglages. Les réglages de revue sont isolés ; aucune préférence habituelle n’est modifiée. La valeur et son unité forment un seul élément accessible. La [CI macOS `b40d674`](https://github.com/antoineberjoan/sema/actions/runs/39051202379) a réussi les tests et le bundle ; une dernière compilation vérifie le regroupement accessible. Publication inchangée.


## Proximité de l’action d’alerte — en revue

Demande d’Antoine dans le chat du 17 octobre : retirer sema du titre du hub, revoir l’alignement du badge et rapprocher la création d’alerte. Proposition appliquée dans l’aperçu : un bloc aligné à gauche réunit le badge et le bouton juste dessous, centré verticalement à côté de la valeur ; il se replie sous la valeur si nécessaire. La date reste en bas et un seul accès à la création d’alerte figure dans le détail du hub. Le détail de catalogue conserve son action existante.

Critères : titre sans nom redondant, badge et action proches, une seule action d’alerte, ouverture sur le bon repère et annulation sans règle enregistrée. Bundle release compilé et signature stricte valide. Revue native sur le cache BCE réel : titre visible supprimé, badge et action alignés, une seule action d’alerte dans l’arbre accessible, ouverture sur la bonne série puis annulation sans règle enregistrée. Capture `sema-hub-alert-cluster.png` dans les artefacts du chat. Les 17 tests Python et les garde-fous passent ; les tests Swift locaux restent indisponibles faute du module `Testing`, la CI vérifie la branche. Les petites largeurs et le mode clair restent à observer. Publication inchangée.


## Libellés de lecture et alerte légère — en revue

Antoine accepte dans le chat du 17 octobre les recommandations : « Euro / Dollar », « USD » et un bouton d’alerte moins massif. Le formatage commun des paires déjà vérifiées donne un titre français et le code devise ; aucune détection par titre ni réécriture du cache. Les titres des autres séries restent inchangés. Le sens inverse garde « Dollar / Euro » et son unité euro existante. Le popover conserve explicitement le libellé officiel, l’unité complète et les dates.

Le bouton d’alerte devient un petit contrôle natif secondaire sous le badge ; ses conditions de disponibilité et son action restent inchangées. Critères : observer le titre et l’unité courts dans le hub et sa navigation, ouvrir le libellé officiel, inverser puis retrouver le sens initial, ouvrir et annuler une alerte. Bundle release compilé et signature stricte valide ; garde-fous et 17 tests Python réussis. Revue native isolée : titre et unité courts observés dans le hub et la sidebar ; inversion vers « Dollar / Euro », puis retour vers « Euro / Dollar » ; popover affichant le libellé officiel complet et l’unité fournisseur. Le bouton secondaire utilise l’accent adaptatif pour garder son contraste en mode sombre. La CI vérifie les tests Swift, indisponibles localement faute du module `Testing`. Publication inchangée.
