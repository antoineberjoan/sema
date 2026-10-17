# Actualisation quotidienne et publication

Statut : code et distribution vérifiés, fusion et contrôle de production en cours, 17 octobre 2026. Source : Antoine dans le chat demande lancement, réveil et exécution même avec hub fermé, puis publication sur origin/main et en production. Il retient une fois par jour après comparaison avec 30 minutes. Notion Produit est à mettre à jour avec ce remplacement de la règle manuelle.

## Résultat observable

Le cache de chaque série conserve sa date de synchronisation. Au lancement et au réveil, seules les séries suivies, activées et connectées dont le cache a au moins 24 h sont actualisées. Une échéance native couvre aussi une app restée ouverte sans fenêtre ; elle suit la plus ancienne synchronisation et ne repart pas pour 24 h à chaque lancement. Aucune actualisation concurrente. Les alertes existantes s’évaluent sur les observations téléchargées, sans nouveau moteur ni permission automatique.

L’horloge de publication de la source ne sert pas de date de synchronisation. Les [changes BCE](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html) sont publiés une fois par jour ouvré ; la fréquence des autres séries reste dans leurs métadonnées. Une vérification quotidienne peut donc attendre le lendemain après une publication. ⌘R force toujours l’actualisation.

## Mise en œuvre et validation

Politique pure dans MarketCore ; contrôleur AppKit conservé par le délégué d’app ; minuteur commun, notifications de veille/réveil, annulation à la sortie. Aucun serveur ni dépendance ajouté. Sans clé Webstat, les sources publiques déjà connectées restent admissibles ; les exemples fictifs ne sont pas actualisés sans connexion. Les caches et règles restent conservés en erreur. Un échec se réessaie automatiquement à l’échéance suivante ; ⌘R permet de réessayer avant.

À vérifier : échéance, cache conservé entre lancements, horloge reculée, contrôles au réveil, exécution sans fenêtre, exclusion des sources désactivées, déduplication, tests et bundle. Puis intégrer les corrections natives et la landing dans main, construire le DMG immuable, publier le même artefact au téléchargement et dans le cask sema-app, tester installation/mise à jour et vérifier getsema.app. Le checkout canonique et le chantier de refactorisation agentique restent préservés.

Première preuve locale : le contrôleur de production a été compilé avec un AppStore factice sans aucune fenêtre. Lancement idempotent, réveils simulés, cache récent ignoré, série ancienne ciblée seule, requête déjà en cours respectée, pause/reprise et arrêt vérifiés. Le scénario d’échec conserve exactement les données. Ce test n’est ni une mise en veille matérielle ni une validation du réseau fournisseur. Les 17 tests Python passent ; Swift Testing est absent du SDK local et sera exécuté en CI.

Le profil natif de revue a été préparé avec 1 537 observations réelles de la série BCE EUR/USD, puis sa seule date de synchronisation a été vieillie de 25 h. Après lancement du bundle local, le cache est redevenu récent sans action d’actualisation manuelle. La source, les observations et l’identification réelle restent conservées. L’accès de contrôle à la fenêtre a expiré : cette lecture du cache prouve la requête au lancement, pas une mise en veille matérielle ni une attente réelle de 24 h.

CI de la branche intégrée `fc903dc` réussie (runs `39046860862` et `39046861387`) : tests et bundle. La landing minimale et le cask sema-app sont intégrés, avec les suppressions demandées conservées ; la refactorisation agentique ultérieure reste dans sa branche distincte.

Le DMG 0.6.0 est publié. Le téléchargement public sans authentification correspond au SHA-256 et à la taille de la construction. Le cask public `908bc97` a passé la vraie mise à jour 0.5.1 → 0.6.0 puis une installation neuve : signature stricte, quarantaine et identité du binaire vérifiées, app de test désinstallée. Les préférences habituelles n’ont pas été utilisées. [Preuves de livraison](../validation/distribution-0.6.0.json).
