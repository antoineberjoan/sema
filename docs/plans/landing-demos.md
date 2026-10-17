# Démonstration de la landing

Statut : nouvelle proposition motion vérifiée en aperçu, publication en attente, 17 octobre 2026. Source : chat d’Antoine ; page Notion Marque `3fbd18bb0dea818fa7f4fc7483c767b3` relue. Branche `codex/landing-demos`, [PR #2](https://github.com/antoineberjoan/sema/pull/2). Checkout canonique et travaux natifs préservés.

## Intention et périmètre

Antoine rejette les trois présentations précédentes, demande la commande Homebrew visible et copiable comme chez Monocle, le retrait de la ligne de compatibilité sous le téléchargement, puis la suppression de la page de téléchargement. Il évoque une vidéo motion comme nouvelle piste. Ces retraits sont demandés ; la vidéo reste une proposition à approuver avant publication.

Le CTA télécharge le DMG existant. La release reste 0.5.1. À la demande suivante d’Antoine, le cask public est renommé `sema-app` et la commande `brew install --cask sema-app` est testée réellement. Sur un Mac neuf, elle nécessite de préparer notre tap et d’approuver ce cask précis ; Antoine demande ensuite de retirer toute cette aide de la landing : seule la commande courte y reste affichée et copiable. La préparation demeure dans la documentation technique. `/download/` ne sert plus de page ; seul son manifeste JSON existant est conservé.

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

- Commande courte exacte issue du manifeste, typographie légère, copie au clic et au clavier avec retour « copié ». Le statut de disponibilité Homebrew reste distinct de la copie du texte.
- Aucun lien interne vers la page supprimée ; le générateur ne recrée ni cette page ni la ligne sous le CTA.
- Film lisible, sans audio ni boucle, poster correct et contrôles clavier ; interruption et état réduit.
- Largeur mobile 390 px sans débordement, liens de téléchargement identiques dans le hero et le header, FAQ, Ko-fi et liens légaux conservés.
- Diff ciblé, syntaxe, génération reproductible et vérification du manifeste sans altérer l’artefact publié.

## Résultats de revue

Ajustement demandé ensuite par Antoine : commande Homebrew en graisse 300 et taille maximale 18 px. Il confirme vouloir afficher `brew install --cask sema-app`. Antoine demande ensuite explicitement le snippet copiable puis son fonctionnement réel. Le cask public est maintenant `sema-app` dans `antoineberjoan/sema`, commit `588119d`, avec un fichier de migration depuis l’ancien nom. Antoine refuse une adhésion Apple Developer : aucune intégration officielle ni notarisation n’est annoncée. Le nom court est opérationnel après préparation de notre tap, pas sur un Mac neuf sans cette préparation. Le manifeste active Homebrew après les essais d’installation 0.5.1 et de mise à jour réelle 0.5.0 → 0.5.1 dans un dossier temporaire. Signature vérifiée, quarantaine préservée ; aucun lancement Internet. [Preuves](../validation/homebrew-sema-app.json).

La copie conserve exactement la commande affichée ; aucune commande de préparation ni nom de compte ne s’ajoute au snippet. Le générateur a été vérifié pour l’idempotence, les commandes du manifeste, le refus d’activation sans preuve et la conservation de la page de téléchargement supprimée.
- Film H.264 1440 × 900, 30 images/s, 18 s, 341 145 octets, aucune piste audio. Poster, recherche, sidebar et image finale relus après encodage.
- Aperçu du commit `7f146cc` READY : déploiement `dpl_GVREFav48TUDvVuai6aD8gdPwNNm`. Copie exacte observée au clic et avec Entrée ; presse-papiers restauré après le test. CTA hero et header pointent vers le même DMG existant.
- 1280 × 800 et 390 × 844 : hero simplifié, commande visible, film et contrôles natifs. Document mobile 390 px, vidéo 350 px, aucun débordement. Lecture clavier observée, film terminé à 18 s, sans boucle.
- Contrôles isolés : copie et son repli manuel, état réduit sans lecture automatique, lecture unique, pause au masquage et à la réduction du mouvement. Seuil de visibilité affiné à 35 % pour arrêter le film lorsqu’il devient marginal à l’écran. Le mode Réduire les animations n’a pas été activé dans macOS pendant cette revue.
- Générateur : états actif et inactif, idempotence, refus de marqueurs manquants et de Homebrew non validé sans écriture partielle. Aucune page ou ligne de compatibilité recréée. IDs, ARIA, fichiers locaux, syntaxe et diff contrôlés.
- `./scripts/check.sh` local bloqué par l’absence du module Swift Testing dans les Command Line Tools ; aucun réglage modifié. CI du commit `7f146cc` verte, runs `39038508038` et `39038513859` (tests et bundle).
- Captures : `sema-landing-motion-desktop.png`, `sema-landing-motion-mobile.png` dans les artefacts du chat. Décisions de retrait et statut de proposition vidéo reportés dans Notion Marque.

Prochaine action : présenter le nouvel aperçu à Antoine ; attendre sa décision sur la vidéo et la publication. La production n’est pas modifiée par cette branche.

Contrôle du cask actif : aperçu du commit `7ebfcaa`, READY (`dpl_4XNeHnuBEDHYHHMw1mhHdv8xRWHP`). La copie au clic donne exactement `brew install --cask sema-app`, presse-papiers restauré ; le bloc de préparation a ensuite été retiré à la demande d’Antoine. La CI de ce commit passe (runs `39043607398` et `39043603762`).
