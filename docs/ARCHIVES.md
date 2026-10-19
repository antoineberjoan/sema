# Référence et archives du projet

Le 17 octobre 2026, les sources de l’app et le site ont été réunis sur `origin/main` du dépôt privé `antoineberjoan/sema`. L’historique complet du site est importé sous `site/`.

- App : `Sources/`, `Tests/`, `Resources/`, `scripts/` et `docs/`.
- Landing, téléchargement et marque : `site/`, avec l’identité Sites existante préservée.
- Distribution : `distribution/`, miroir du cask public `antoineberjoan/homebrew-sema`.
- Livrables et essais historiques : archive privée [workspace-archive-2026-10-17](https://github.com/antoineberjoan/sema/releases/tag/workspace-archive-2026-10-17), accompagnée de son inventaire SHA-256 et des exclusions. Elle comprend 1 013 fichiers : anciennes maquettes, ressources, rapports, copies de revue et historiques Git. L’archive fait 223 268 853 octets ; SHA-256 `615efedd673bd4c94be77655e6bad9800bc3a64699e0cb93d06a6316c09ef311`. Les 59 exclusions sont détaillées dans l’inventaire.

Les clés, sessions, données personnelles de test et caches de compilation ou téléchargement ne sont pas publiés. Les copies locales obsolètes sont retirées seulement après vérification de la récupération de l’archive depuis GitHub. L’archive ne constitue pas une version distribuée de l’app.

L’archive a été retéléchargée depuis GitHub et chaque empreinte de l’inventaire a été vérifiée avant nettoyage : [preuve de récupération](validation/archive-recovery-2026-10-17.json). Les anciennes copies et les caches locaux ont été déplacés hors du dossier de travail, vers la Corbeille, pour permettre un retour en arrière. Seule la copie canonique sur `main`, synchronisée avec `origin/main`, reste dans le dossier du projet.

## Nettoyage GitHub

Le 17 octobre, les deux dépôts nécessaires conservent chacun uniquement leur branche `main` : sources privées dans `antoineberjoan/sema`, distribution publique dans `antoineberjoan/homebrew-sema`. Les tags temporaires `archive/catalogue-2026-10-17` et `archive/distribution-2026-10-17` sont retirés ; leurs historiques restent dans le bundle Git de l’archive privée.

La release publique et le tag `v0.2.0` sont retirés après vérification de leurs trois fichiers dans l’archive privée. Les métadonnées de cette ancienne release y sont aussi conservées sous `release-0.2.json`. Le dépôt public propose uniquement `v0.4.0`. Son tag correspond au commit du cask 0.4.0 ; le DMG, son URL et son SHA-256 restent inchangés, avec un téléchargement sans authentification revérifié. [Preuves](validation/github-cleanup-2026-10-17.json).

## Préparation de l’ouverture — 19 octobre 2026

Antoine a retenu le principe d’une ouverture sous licence MIT ; la licence est ajoutée au dépôt. La [Stratégie](https://app.notion.com/p/3fbd18bb0dea819bad4bc31bca0ad436) consigne cette décision. La visibilité reste privée : la release `workspace-archive-2026-10-17` expose une archive de travail de 223 Mo si tout le dépôt devient public. Sa suppression sans sauvegarde a été soumise à Antoine ; aucune suppression ni ouverture n’a encore été effectuée.

Le contrôle ciblé de l’historique Git local a examiné 1 253 versions de fichiers texte sans trouver les formats de secrets recherchés. Ce contrôle n’est pas une garantie exhaustive et ne couvre pas les pièces de release, les images ni les références distantes non récupérées. Le package Swift n’a aucune dépendance externe déclarée. Les conditions des données économiques restent propres aux fournisseurs. [État des vérifications](validation/open-source-readiness.json).
