# Navigation clavier et bandeau Repère

Statut : ajustement du bandeau et des quatre flèches en cours, 17 octobre 2026.

Demande complémentaire d’Antoine dans le chat du 17 octobre : ←/→ identiques à ↑/↓, avec ou sans ⌘ ; quatre favoris en plus de la signature, cartouche toujours visible et teinté par Apparence, cartes plus carrées et retrait du badge « Démo » du bandeau. Les préférences et l’ordre personnel restent conservés.

Critères de cette correction : observer les quatre directions dans le hub, la validation du sélecteur avec ⌘←/→, quatre favoris et la signature simultanément, le maintien de cette signature pendant le défilement et sans favoris, puis sa couleur dans Graphite et un thème coloré. Vérifier également une position latérale et une largeur d’écran réduite.

Source : demande d’Antoine dans le chat du 17 octobre, après les quatre maquettes du sélecteur. Direction retenue : Repère. Recommandation appliquée : flèches immédiates dans Focus ; ⌘ + flèches ouvre un aperçu visuel, relâcher ⌘ valide, Entrée valide aussi, Échap annule. Cinq périodes proposées : 3 mois, 1 an, 3 ans, 5 ans, Tout. Jusqu’à quatre favoris visibles selon la largeur, sans modifier la sélection existante.

Sources consultées : [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296), [Marque](https://app.notion.com/p/3fbd18bb0dea818fa7f4fc7483c767b3), [contrat actuel](../PRODUCT.md), Interface Craft. Les recommandations restent identifiées comme telles ; elles ne changent pas le périmètre des données.

## Critères observables

- Deux raccourcis globaux configurables ouvrent le bandeau et le hub, même depuis une autre app ; les conflits sont signalés et le réglage précédent est conservé.
- Les flèches de Focus suivent l’ordre personnel. Le sélecteur ne change pas le graphique avant validation ; annulation, changement de fenêtre et ouverture d’une feuille ferment l’aperçu sans sélectionner.
- Saisie, recherche, réglages et raccourcis de réorganisation gardent leur clavier natif.
- Repère affiche cinq périodes sans fond commun supplémentaire. Quatre cartes de données peuvent être visibles ; les autres favoris et la signature restent accessibles par défilement.
- Préférences anciennes, favoris et ordre conservés ; aucun nouvel appel réseau ; mouvement réduit et transparence réduite pris en compte.

## Résultat et preuves

- Bundle local `dist/Sema.app` compilé en release et signature ad hoc vérifiée. L’app est rouverte depuis ce chemin canonique, avec la sélection personnelle conservée. Les quatre favoris initiaux concernent seulement une nouvelle installation.
- Contrôles de structure et `git diff --check` réussis. Les 17 tests Python des outils passent. `./scripts/check.sh` s’arrête ensuite : le module Swift `Testing` manque dans les Command Line Tools de ce Mac ; aucune modification des contrôles pour contourner cette limite.
- [CI macOS réussie sur `c9ab623`](https://github.com/antoineberjoan/sema/actions/runs/39019838396) : 17 tests des outils, 77 tests Swift et construction du bundle. La première CI avait signalé une expression SwiftUI trop longue ; la composition de `WorkspaceView` est répartie en trois propriétés, sans changement de parcours. Le dernier bundle est compilé localement puis réinstallé après cette correction.
- Sonde compilée contre le cœur réel : document v2 ancien inchangé, sélection vide conservée, raccourci personnalisé et action désactivée relus après sauvegarde. Les tests de persistance correspondants vivent dans `ShortcutPreferencesTests.swift`.
- Sonde contre le contrôleur Carbon réel, hors sandbox : réservation exclusive concurrente refusée, ancien raccourci conservé après erreur, suspension et réenregistrement réussis. Le premier essai sandboxé renvoyait l’erreur système `eventInternalErr` ; le test hors sandbox réussit.
- Observé dans le bundle natif : ↑ / ↓ depuis la liste et Focus, validation de ⌘↓ au relâchement, recherche saisie sans sélection intempestive du graphique, enregistrement d’une combinaison, refus de ⌘K et d’un doublon, effacement, remise à zéro, ouverture et fermeture du bandeau, changement de période. Quatre cartes ont été observées avec les favoris de test ; les trois favoris personnels restent inchangés.
- Sortie du champ par Tabulation et clic extérieur observée dans le dernier bundle ; la combinaison enregistrée reste intacte. La fenêtre locale est laissée sur Raccourcis.
- Rail final contrôlé en clair et en sombre, libellé « 3 mois » intégral. Le mode Système d’origine est rétabli. Captures conservées dans les artefacts de la conversation : `sema-raccourcis-20261017.png`, `sema-repere-final-20261017.png`, `sema-repere-clair-20261017.png`.
- Les demandes produit et le choix Repère sont reportés dans les pages Notion sources. Les cinq périodes et la validation au relâchement y restent identifiées comme recommandations en essai local.

## Validation restante

L’outil envoie les raccourcis locaux mais le déclenchement des réservations globales par ses touches synthétiques n’a pas été observé. Une question de test physique ⌃⌥B / ⌃⌥H est en attente auprès d’Antoine. Le contrôle natif a été réinitialisé après des délais d’attente lors du passage dans Finder ; la revue a ensuite repris normalement.

Le maintien de ⌘ pendant plusieurs choix, Échap avant relâchement et le rendu du sélecteur maintenu restent à observer avec un clavier physique. Les événements de l’outil relâchent la combinaison avant la lecture de l’écran. Réduire les animations, Réduire la transparence et Augmenter le contraste sont pris en charge dans le code ; ces réglages système n’ont pas été modifiés pendant la revue.

Prochaine action : recueillir le test physique et corriger tout écart. Code sauvegardé sur `origin/codex/keyboard-navigation` ; le dossier de travail partagé reste sur sa branche initiale. Les bundles et données de revue temporaires sont supprimés après l’installation canonique ; les sources et captures utiles restent conservées.

Publication : aucune nouvelle release publique ni fusion dans main dans ce lot. Les branches de sidebar et de démos du site restent séparées de ce travail local.
