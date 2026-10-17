# Démonstrations de la landing

Statut : refonte implémentée et vérifiée en aperçu, publication en attente, 17 octobre 2026. Antoine rejette dans le chat la répétition du même écran sur les trois sections ; il demande des compositions et animations différentes, dans l’esprit de Monocle et Resurf. Marque Notion relue : `3fbd18bb0dea818fa7f4fc7483c767b3`.

## Direction retenue pour la revue

Conserver les fonctionnalités les unes sous les autres, sans onglets. Chaque section change d’échelle et de composition :

| Usage | Composition | Mouvement à la première arrivée |
| --- | --- | --- |
| Bandeau | Quatre cartes de verre au-dessus d’un bureau illustré ; la base se fond dans la page, le texte suit le visuel. | Cartes entrantes en 650 ms, décalées de 95 ms ; tracé des mini-courbes après 320 ms. |
| Recherche | Composition asymétrique : grandes touches ⌘ K à gauche, commande flottante à droite. Aucun second bureau. | Pression des touches, mot révélé à partir de 430 ms, puis résultats à partir de 850 ms. |
| Focus | Valeur et courbe agrandies directement sur le fond de page, sans fenêtre ni carte. | Tracé sur 1 800 ms ; point final et variation à partir de 1 580 ms. |

Une orchestration dans `product-demo.js`, valeurs nommées, aucune boucle permanente ni défilement intercepté. Les valeurs restent fixes ; aucun faux flux de marché. Réduire les animations, masquer l’onglet ou quitter la page annule les animations et expose l’état final. Sans JavaScript, les visuels sont complets. Les illustrations conservent leurs descriptions accessibles indiquant les valeurs fictives ; les contrôles dessinés restent inertes.

Références observées : [Monocle](https://trymonocle.app/) pour le bureau en contexte puis les fragments de réglages ; [Resurf](https://resurf.so/) pour les démonstrations isolées à des échelles différentes. Aucun asset, code ou texte de ces sites n’est copié.

## Vérification

Critères : compositions reconnaissables et distinctes ; navigation naturelle ; texte et chiffres lisibles à 390 px ; aucune interaction requise pour comprendre les fonctions ; progression des scènes une seule fois ; état réduit et interruption ; header de téléchargement, logo, aide, Ko-fi et liens légaux conservés.

Branche existante `codex/landing-demos`, [PR #2](https://github.com/antoineberjoan/sema/pull/2) ; checkout canonique et modifications natives préservés.

- Aperçu `d0eccc3` : Vercel READY, `dpl_9WkbLJ1MRLJ27tymwVSnT4iJQ4hn`, https://sema-qiue82xjf-antoine-berjoan.vercel.app/. Lien temporaire créé dans le périmètre de revue précédemment autorisé ; aucun secret dans Git.
- 1280 × 720 : bandeau à quatre cartes avec contexte de travail, recherche asymétrique avec touches, historique directement sur la page ; header de téléchargement visible après le CTA. Les scènes restent dans le flux et ne se rejouent pas au retour.
- 390 × 844 : deux cartes lisibles, recherche empilée et historique cadré ; largeur de document 390 px, figures 350 px. Captures cohérentes obtenues avec `tab.screenshot`. 820 px : quatre cartes et leurs noms financiers contenus, sans débordement.
- Parcours clavier : depuis Homebrew, Tab atteint directement la première question ; les faux contrôles des illustrations ne prennent pas le focus. Téléchargement et URLs de release inchangés, pas de nouveau téléchargement ou installation pendant cette revue.
- Recherche observée en apparition, puis résultats complets ; styles finaux lisibles. Ajustement final : déclencher le tracé de l’historique à l’arrivée de la zone graphique, plutôt que dès l’arrivée de sa valeur.
- Contrôle isolé du contrôleur : état réduit immédiat, observation retirée après l’entrée, animations annulées au masquage, à la réduction du mouvement et à la sortie de page. La préférence système de mouvement n’a pas été changée ; ce mode n’a pas été observé dans le navigateur.
- HTML, IDs, ARIA, références locales, syntaxe JavaScript et diff vérifiés ; aucune dépendance ajoutée. CI verte sur `d0eccc3` : run `39036643226`. Aucun message d’erreur de la landing observé ; le journal conservait seulement une erreur de la page de connexion Vercel visitée avant l’accès à l’aperçu.
- Captures locales de revue : `sema-landing-scenes-desktop.png` et `sema-landing-scenes-mobile.png` dans les artefacts du chat. La précision d’Antoine sur les compositions distinctes est reportée dans Notion Marque.

## Téléchargement — proposition en aperçu

Antoine questionne le 17 octobre l’utilité de la page de téléchargement et son écart de sobriété avec la landing. Proposition préparée pour revue : le CTA de la landing télécharge directement le DMG publié ; `/download/` devient une aide facultative, sans nouvelle présentation du produit, démonstration ni replay. Trois étapes, puis aide macOS, Homebrew et mises à jour repliées. Cette proposition n’est pas encore une décision produit validée par Antoine.

La landing conserve la compatibilité et la mention de préversion non notarisée près du téléchargement. `sync-download.py` génère les deux CTA et les informations de version à partir du seul manifeste publié 0.5.1 ; la version native et son artefact ne changent pas. Le header reprend le lien principal et reste inerte si aucun téléchargement n’est actif.

Critères : téléchargement direct fonctionnel ; aide lisible sur ordinateur et mobile ; liens d’ancre ouvrant la bonne réponse ; parcours clavier ; copie Homebrew ; manifeste et SHA-256 de la release inchangés. Preuves de l’aperçu `e7f81b8` :

- Vercel READY : `dpl_G1bZC3YFLBxcEK64sYMKspyzHA3B`, https://sema-nxmb718d3-antoine-berjoan.vercel.app/ ; accès temporaire de six heures dans l’autorisation initiale, secret non conservé ici.
- Clic réel depuis la landing : `Sema-0.5.1-arm64.dmg` reçu dans Téléchargements. SHA-256 mesuré : `762e891f57f26db57c222f78c899e1d58bf432ef6b72a2623eda196bbf4c526d`, identique au manifeste. Aucune ouverture ou installation du DMG pendant cette revue. Le contrôle de téléchargement du navigateur a rendu son résultat avec un délai anormalement long.
- Aide à la première ouverture et Homebrew : navigation depuis la landing, ouverture automatique de la bonne réponse ; copie de la commande exacte vérifiée, presse-papiers restauré ; repli au clavier avec Entrée.
- Ordinateur 1280 × 720 : page compacte observée. Mobile 390 × 844 : largeur du document de 390 px et commande Homebrew contenue dans 350 px, contrôlées dans le DOM ; la capture du navigateur après redimensionnement est incohérente et ne constitue pas une validation visuelle mobile.
- HTML/ARIA/assets, syntaxe JS et Python, manifeste inchangé et diff vérifiés. Contrôle du générateur : idempotence, changement de release sur les deux CTA, désactivation des CTA et refus sans mise à jour partielle si le bloc de landing est absent.
- CI GitHub verte : run `39030638120` sur `e7f81b8`.
- Captures locales : `sema-installation-minimale-20261017.png` et `sema-installation-mobile-20261017.png` (limite mobile ci-dessus).

## Suite

La PR est prête à présenter. Aucun changement fusionné sur main, aucun changement du site public ni du téléchargement natif 0.5.1. Le checkout canonique et son index `codex/agent-foundation` sont préservés. Après autorisation de publication couvrant cette version : fusionner, contrôler le déploiement et le rendu public. La publication de l’app 0.5.2 reste une action distincte.
