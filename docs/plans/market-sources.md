# Connexions personnelles et catalogues de cours

Statut : intégré localement à `codex/agent-foundation`, sur la base `f1a5834`, le 17 octobre 2026. Validation Swift complète en CI et tests du catalogue avec clés personnelles restants. Aucun push, aucune fusion vers main ni publication.

## Intention et périmètre

Source : Antoine demande dans cette conversation du 17 octobre des connexions Twelve Data et Alpha Vantage comme Webstat, avec lien officiel d’obtention de clé, catalogue visible directement et choix de repères. Il demande ensuite explicitement l’intégration dans la branche principale du chantier. Le travail isolé a été adapté au rangement actuel des fichiers, sans restaurer les vues ou contrôleurs supprimés par les refactorisations.

Chaque utilisateur fournit sa clé personnelle. Aucun secret partagé, serveur ni dépendance ajouté. Exception autorisée par Antoine pour Alpha Vantage : `apikey` dans la requête HTTPS vers l’hôte officiel, car aucun autre mode d’authentification n’est documenté. Le transport utilise une session éphémère sans cache HTTP ni redirection ; aucune URL authentifiée ni réponse d’erreur brute n’est journalisée. Twelve Data utilise Authorization.

## Contrat intégré

- Sources dans les réglages : activation, connexion, remplacement et retrait, champ protégé et lien officiel sous le champ. `SourceKeychain` remplace l’adaptateur Webstat en préservant son service et son compte exacts ; les nouvelles sources ont des services séparés.
- Explorer montre le catalogue de la source dès son ouverture. Le filtre par nom, symbole et place est local. Les métadonnées restent en mémoire pendant la session et sont invalidées au remplacement ou retrait de clé ; aucun appel par frappe.
- Twelve Data : `api_usage.plan_category`, puis `stocks`, `etf` et `indices` avec `show_plan=true`. Filtrage par `access.plan` individuel ou `access.plan_business` Business. Droits absents ou inconnus exclus ; forfait de compte inconnu signalé. Aucun droit déduit du quota. Un catalogue tronqué est refusé. Il s’agit des niveaux publiés, pas d’un test de chaque cours ou des accords de place.
- Alpha Vantage : `LISTING_STATUS&state=active`, actions et ETF américains. Ce catalogue de couverture ne décrit pas les droits individuels ; l’aperçu confirme l’accès effectif. CSV cité, guillemets doublés, BOM et CRLF reconnus ; lignes tronquées refusées et titres radiés exclus.
- Aperçu avant ajout, fournisseur/symbole/place et fréquence distincts. Un ETF reste un ETF, sans être présenté comme son indice sous-jacent. Les données sont Decimal, avec devise et provenance conservées dans le cache.
- Cours non ajustés : Twelve Data `adjust=none`, Alpha Vantage TIME_SERIES_DAILY ou TIME_SERIES_WEEKLY. Quotidien gratuit Alpha Vantage limité à 100 séances ; hebdomadaire pour l’historique long. Les fréquences ont des identifiants distincts et ne sont pas fusionnées.
- Actualisation raccordée au mécanisme de la branche : séries suivies uniquement, cache préservé en cas d’échec ; refus de quota ou de clé suspend le reste du lot pour ce fournisseur. Espacement conservateur Twelve Data 8/minute et Alpha Vantage 1,1 seconde. Catalogue, validation et aperçu consomment aussi des appels.
- La branche d’intégration ne contient plus RefreshController/RefreshPolicy présents dans l’ancienne base du patch. Aucun contrôleur quotidien n’a été recréé dans ce lot ; son éventuel retour relève du chantier principal.

Les devises, crypto, fondamentaux et autres endpoints ne sont pas inclus dans ce catalogue initial. Tiingo n’est pas intégré : les conditions Starter consultées interdisent le stockage durable nécessaire au cache. Les droits d’affichage et accords de place restent à vérifier pour l’usage de chaque forfait par des utilisateurs externes.

Références : [documentation Twelve Data](https://twelvedata.com/docs/mcp), [Alpha Vantage](https://www.alphavantage.co/documentation/), [contrats des sources](../DATA-SOURCES.md).

## Preuves

- Branche initialement propre, intégration ciblée dans Markets, Explorer, Settings et les extensions existantes d’AppStore. Une seule implémentation ; aucune copie active des anciennes vues.
- Compilation debug de l’app intégrée réussie. Garde-fous et 38 tests Python passent. Quatorze tests Swift ajoutés pour les données et catalogues ; `./scripts/check.sh` reste bloqué par l’absence du module Testing dans les Command Line Tools locaux.
- Sondes liées aux objets réellement utilisés par l’app intégrée : précision Decimal, identité, cache rétrocompatible, fréquences distinctes, erreurs, ETF, clé vide ; forfaits, catalogue incomplet, dédoublonnage, CSV cité/CRLF/BOM, cache et invalidation, transports simulés des deux fournisseurs. Aucun réseau ni clé personnelle pour ces sondes.
- Script de bundle lancé : compilation passée, génération d’icône échouée avec Invalid Iconset. La copie de revue utilise l’icône de la release existante ; signature ad hoc vérifiée. Identifiant distinct `com.antoineberjoan.sema.market-integrated`, profil vierge `/private/tmp/sema-market-integrated-data` ; aucune clé saisie ni retirée.
- Vérification native de l’app intégrée : fournisseurs dans le sélecteur Explorer ; Twelve Data sans clé ; ouverture de Sources ; champs protégés et liens officiels des deux fournisseurs ; désactivation/réactivation Twelve Data et champ désactivé observé. Copie de revue quittée par son menu.
- Avant intégration, vue de catalogue vérifiée dans un harnais sans réseau : liste initiale, filtre SPY, sélection ETF, changement de source effaçant l’aperçu, aucun résultat et filtre effacé. Ce harnais ne valide pas le graphique complet.

## Limites de vérification et suite

Des appels réels antérieurs ont validé les deux clés et leurs cours AAPL : Twelve Data 5 000 séances/2 393 semaines ; Alpha Vantage 100 séances/1 406 semaines. FCHI apparaissait dans les métadonnées Twelve Data mais ses cours étaient indisponibles ; SPX Alpha Vantage exigeait une habilitation. Aucun accès gratuit au CAC 40 ou S&P 500 n’est promis.

Les nouveaux essais de catalogue avec les clés personnelles ont été rejetés par le contrôle automatique, qui ne reconnaît pas l’autorisation antérieure comme vérifiable. Les métadonnées et plan_category ont été observés avec la clé publique demo. Aucune tentative de contournement ni transmission personnelle supplémentaire pendant l’intégration.

Le retrait de la clé Twelve Data de l’ancien profil isolé reste reporté à la demande d’Antoine ; ne pas le reprendre sans nouvelle demande. Aucun changement aux entrées personnelles du Trousseau.

Prochaine validation : exécuter la suite Swift sur le toolchain CI habituel, puis vérifier les catalogues avec un compte personnel autorisé. Le commit local du chantier est le point de reprise ; le patch temporaire était seulement le support de transfert initial.
