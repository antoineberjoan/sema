# Démonstration de la landing

Statut : nouvelle proposition motion vérifiée en aperçu, publication en attente, 17 octobre 2026. Source : chat d’Antoine ; page Notion Marque `3fbd18bb0dea818fa7f4fc7483c767b3` relue. Branche `codex/landing-demos`, [PR #2](https://github.com/antoineberjoan/sema/pull/2). Checkout canonique et travaux natifs préservés.

## Intention et périmètre

Antoine rejette les trois présentations précédentes, demande la commande Homebrew visible et copiable comme chez Monocle, le retrait de la ligne de compatibilité sous le téléchargement, puis la suppression de la page de téléchargement. Il évoque une vidéo motion comme nouvelle piste. Ces retraits sont demandés ; la vidéo reste une proposition à approuver avant publication.

Le CTA télécharge le DMG existant. Aucun changement de release, de cask, de données natives ou de configuration de sécurité. La cible retenue ensuite est `brew install --cask sema-app`, affichée comme commande prévue et sans copie tant qu’elle n’est pas disponible pour une machine neuve. `/download/` ne sert plus de page ; seul son manifeste JSON existant est conservé.

## Proposition motion

Une seule séquence silencieuse de 18 secondes remplace les trois blocs de démonstration. `scripts/render-demo.swift` dessine les images, encodées en MP4 H.264 ; aucun outil de capture ni nouvelle dépendance de production. Ce sont des illustrations d’interface avec valeurs fixes, pas une captation native.

| Temps | Action |
| --- | --- |
| 0–5 s | Le pointeur ouvre quatre favoris dans le bandeau ; les mini-courbes se tracent. |
| 5–9,4 s | ⌘K, saisie d’euro, apparition des résultats et sélection. |
| 9,4–16 s | Focus, tracé de l’historique, apparition de la sidebar au survol puis fermeture. |
| 16–18 s | Graphique au repos et signature. |

Lecture automatique une fois en vue, sans boucle. Pause hors écran et au masquage. Réduire les animations conserve un poster et les contrôles manuels. Une description accessible raconte toutes les actions et identifie les valeurs fictives. Les chiffres ne simulent pas un flux de marché. La commande Homebrew se copie sans changer de largeur ; un échec de presse-papiers sélectionne le texte pour une copie manuelle. Sans JavaScript, le téléchargement, la commande sélectionnable et la lecture native restent disponibles.

## Critères et preuves

- Commande prévue exacte issue du manifeste, typographie légère ; aucun bouton de copie actif pour une commande non disponible. Le chemin actif conserve sa copie pour une distribution validée.
- Aucun lien interne vers la page supprimée ; le générateur ne recrée ni cette page ni la ligne sous le CTA.
- Film lisible, sans audio ni boucle, poster correct et contrôles clavier ; interruption et état réduit.
- Largeur mobile 390 px sans débordement, liens de téléchargement identiques dans le hero et le header, FAQ, Ko-fi et liens légaux conservés.
- Diff ciblé, syntaxe, génération reproductible et vérification du manifeste sans altérer l’artefact publié.

## Résultats de revue

Ajustement demandé ensuite par Antoine : commande Homebrew en graisse 300 et taille maximale 18 px. Il confirme vouloir afficher `brew install --cask sema-app`. La maquette affiche ce nom comme commande prévue ; sa copie est inactive. L’API du catalogue officiel répond 404 le 17 octobre 2026, et le cask public actuel reste `sema` dans `antoineberjoan/sema`. La version 0.5.1 est signée ad hoc et non notarisée ; son intégration officielle reste à préparer après les contrôles Gatekeeper exigés par Homebrew. Ne pas présenter la commande courte comme opérationnelle ni soumettre une validation fictive. La commande complète précédemment testée reste dans le manifeste, avec Homebrew désactivé sur cette proposition de landing.

- Film H.264 1440 × 900, 30 images/s, 18 s, 341 145 octets, aucune piste audio. Poster, recherche, sidebar et image finale relus après encodage.
- Aperçu du commit `7f146cc` READY : déploiement `dpl_GVREFav48TUDvVuai6aD8gdPwNNm`. Copie exacte observée au clic et avec Entrée ; presse-papiers restauré après le test. CTA hero et header pointent vers le même DMG existant.
- 1280 × 800 et 390 × 844 : hero simplifié, commande visible, film et contrôles natifs. Document mobile 390 px, vidéo 350 px, aucun débordement. Lecture clavier observée, film terminé à 18 s, sans boucle.
- Contrôles isolés : copie et son repli manuel, état réduit sans lecture automatique, lecture unique, pause au masquage et à la réduction du mouvement. Seuil de visibilité affiné à 35 % pour arrêter le film lorsqu’il devient marginal à l’écran. Le mode Réduire les animations n’a pas été activé dans macOS pendant cette revue.
- Générateur : états actif et inactif, idempotence, refus de marqueurs manquants et de Homebrew non validé sans écriture partielle. Aucune page ou ligne de compatibilité recréée. IDs, ARIA, fichiers locaux, syntaxe et diff contrôlés.
- `./scripts/check.sh` local bloqué par l’absence du module Swift Testing dans les Command Line Tools ; aucun réglage modifié. CI du commit `7f146cc` verte, runs `39038508038` et `39038513859` (tests et bundle).
- Captures : `sema-landing-motion-desktop.png`, `sema-landing-motion-mobile.png` dans les artefacts du chat. Décisions de retrait et statut de proposition vidéo reportés dans Notion Marque.

Prochaine action : présenter le nouvel aperçu à Antoine ; attendre sa décision sur la vidéo et la publication. La production n’est pas modifiée par cette branche.
