# Validation des catalogues publics — 16 octobre 2026

## Vérifications effectuées

- Compilation de l’exécutable natif et création d’un bundle `.app` avec `scripts/build-app.sh` : succès.
- Bundle de revue distinct, avec répertoire de préférences de test et identifiant `com.antoineberjoan.sema.sources-review`. Aucune installation de l’app et aucune réutilisation de la clé Rheos pour ces vérifications.
- Lecteur Swift exécuté sur les réponses officielles réellement téléchargées : succès pour les cinq services SDMX, la Fed de New York et la Banque mondiale.
- Catalogues reçus : 244 jeux Insee, 105 BCE, 8 138 Eurostat, 29 BRI, 1 550 OCDE. New York expose six familles dans sa réponse de taux de référence ; leurs mesures numériques sont découvertes, sans liste de taux imposée par Sema.
- Structures et observations interprétées : IRL Insee, EUR/USD BCE, prix des logements français Eurostat, taux directeur américain BRI, prix immobiliers réels français OCDE, EFFR/borne de cible/volume New York, croissance française Banque mondiale.
- Historique EFFR reçu : 6 606 observations entre le 3 juillet 2000 et le 15 octobre 2026. Historique de croissance Banque mondiale utilisé : 65 observations. Les autres profondeurs ne sont pas extrapolées à l’ensemble des catalogues.
- Écriture/lecture JSON des nouveaux descripteurs, compatibilité d’une série sans nouveau descripteur, séparation des identifiants fournisseurs et mesures, conservation des `Decimal` et des échelles.
- Refus d’une réponse contenant plusieurs séries, d’un changement d’échelle au niveau des observations et des clés permettant une injection de chemin ; rejet des déclarations d’entités XML.
- Les trois listes de codes externes absentes de la structure IRL (fréquence, géographie, unité) ont été obtenues auprès des références publiées ; leur résolution a été vérifiée.
- Contrôle des requêtes publiques : HTTPS et absence d’en-tête Authorization. L’accès Webstat existant conserve son authentification séparée.

## Contrôle natif observé

Dans la première compilation de revue : choix d’Insee sans clé Webstat, chargement des 244 jeux, recherche « IRL » et ouverture par Entrée, aperçu d’une série réelle, graphique, période trimestrielle, ajout aux repères, état « Ajouté », activation de l’actualisation sans clé Webstat. Les fichiers de préférences et de cache de la session de test ont été conservés.

Le contrôle visuel a montré que le navigateur devait garder une hauteur bornée : source et liste restent fixes, l’aperçu défile dans son propre panneau. Ce correctif et la résolution des listes de codes externes ont été compilés. La revue native suivante, autorisée par Antoine, a aussi contrôlé les réglages de sources et leur effet dans Explorer ; voir [PERSONALIZATION.md](PERSONALIZATION.md).

## Limites de validation

- `scripts/check.sh` a été exécuté, mais la suite Swift Testing ne peut pas se lancer avec les Command Line Tools installés : module `Testing` absent. Les tests ajoutés dans `StatisticalClientTests.swift` restent à exécuter dans Xcode/CI. Le lecteur Swift indépendant a vérifié les contrats de données ci-dessus.
- Aucun test exhaustif de chaque jeu, combinaison, fréquence et droit de réutilisation n’est revendiqué. Les erreurs et périodes non prises en charge restent explicites.
- Les notifications système n’ont pas été activées dans cette session de revue. Le moteur existant de franchissement reste partagé entre sources ; aucune surveillance en arrière-plan n’est ajoutée.
- Les modifications indépendantes de marque, de bandeau et d’apparence présentes dans le même checkout ont été préservées.

## Ko-fi

Le placeholder du pied de page et de la page de téléchargement a été remplacé par `https://ko-fi.com/antoineberjoan`. Trois liens contrôlés, nouvel onglet et `noopener noreferrer`, sans widget ni code de paiement embarqué. Le déploiement Sites a confirmé son succès, en conservant l’audience du site.
