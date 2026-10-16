# Vérification de sema 0.2

16 octobre 2026. Alpha native arm64, macOS 14+, sans dépendance externe.

## Application

- Compilation Swift 6 et bundle ad hoc réussis. Le module Swift Testing manque aux Command Line Tools locaux ; les 48 tests passent dans GitHub Actions sur macOS 15.
- Accueil natif revu : quatre univers et treize choix visibles sans défilement. Sélection individuelle, tout choisir, tout retirer, passage à la connexion et découverte en démonstration contrôlés dans la vraie app. Les deux repères choisis et la fin de l’accueil sont présents dans les préférences isolées.
- Un harness AppStore vérifie ordre, favoris, relancement, retrait et pause des alertes, sélection vide, préférences illisibles et échec atomique de sauvegarde. L’accueil ne se rouvre pas sur un document illisible ; un échec de fin d’accueil ne marque jamais sa réussite.
- Les couleurs utilisent la palette sémantique existante et s’adaptent à l’apparence système. Les mouvements de sélection (180 ms), de signe (360 ms) et d’étape (220 ms) restent facultatifs avec Réduire les animations.

## Webstat réel

La clé autorisée de Rheos a été lue uniquement en mémoire et transmise exclusivement à Webstat. La QA native utilise un relais local à origine fixe et un Trousseau factice ; la vraie clé ne figure dans aucun bundle, préférence, cache ou journal de test.

- Découverte de 47 jeux et 42 761 séries.
- Recherche trimestrielle immobilier : 184 résultats ; inflation France : 375 ; apostrophe : 44 ; expression d’injection : aucun résultat.
- Deux pages de 50 résultats distincts contrôlées contre l’ordre Webstat. Au-delà du plafond de l’endpoint records, un export de sept champs permet de poursuivre : 11 267 055 octets pour les 42 761 résumés, sans observations. La fiche recharge toujours les métadonnées complètes.
- Quatre séries vérifiées : Bund mensuel, indice IPCH France (base 2025), encours d’OPC en milliards d’euros et crédit immobilier trimestriel. Échelle, période et fréquence restent celles de la source.
- Dans l’app native, ajout du Bund, chargement complet jusqu’à janvier 1980 (561 observations reçues), puis création d’un seuil à 3,5. Les données et la règle sont enregistrées dans le dossier QA isolé.
- Les changements d’unité, de multiplicateur et de base suspendent les règles concernées avant remplacement et empêchent de mélanger deux mesures.

## Distribution et limites

Le DMG utilise un fond papier pour conserver les vrais noms noirs du Finder. La signature de l’app est contrôlée après la copie dans l’image, puis sur l’archive montée en lecture seule. Le paquet ne contient aucune configuration de développement.

Une installation puis une mise à jour Homebrew privées utilisent deux vrais DMG et un dossier Applications isolé. Les signatures après installation et la quarantaine sont conservées. Le téléchargement HTTPS sans authentification et l’installation depuis le vrai cask public ont ensuite réussi sur le même artefact final. La signature stricte et la quarantaine sont présentes après installation. Les rapports JSON de release distinguent les portées privées et publiques ; les apps, casks et taps de test sont nettoyés et /Applications reste inchangé.

La page de téléchargement présente une démonstration du geste, jamais une fausse progression de copie. La préversion mobile de 390 px ne déborde pas ; le mode de réduction du mouvement conserve les instructions statiques. Le lien est un vrai lien HTML utilisable sans JavaScript.

Le premier lancement après téléchargement Internet sur un autre compte ou Mac, le parcours Gatekeeper complet, VoiceOver et une revue visuelle exhaustive de toutes les combinaisons de thèmes et d’apparences ne sont pas validés ici. L’app reste non notarisée ; aucun script ne contourne Gatekeeper ni ne retire la quarantaine. Les alertes ne sont évaluées qu’à l’actualisation.
