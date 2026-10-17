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
