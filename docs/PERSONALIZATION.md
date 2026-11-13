# Sources, profil local et soutien


## Réglages natifs

Six rubriques : Général, Sources, Profil, Apparence, Raccourcis, À propos. « Mon espace » ouvre directement Profil ; les actions « Connecter Webstat » ouvrent Sources. Les vues réutilisent les formulaires groupés, les interrupteurs, le sélecteur de fichiers et la typographie système de macOS. Aucune dépendance de production ni nouveau mouvement n’est ajouté.

### Sources

Un interrupteur par source : Webstat, Insee, BCE, Eurostat, BRI, OCDE, Fed de New York et Banque mondiale. À la première ouverture, Webstat, Insee, BCE et Eurostat sont actives ; les quatre autres, plus spécialisées, s’activent dans les réglages. Les préférences existantes ne changent pas. Les réglages n’exposent pas une liste éditoriale de séries : Explorer garde les catalogues complets des sources activées et le choix des jeux et dimensions. Aucun catalogue complet d’observations n’est importé automatiquement.

- Les préférences existantes continuent à rendre toutes les sources accessibles. Aucune hiérarchie ou sélection de fournisseurs n’est imposée.
- Désactiver une source la retire d’Explorer et suspend son actualisation, le chargement d’historique et les alertes correspondantes. Les repères, favoris, règles et observations restent conservés. La connexion Webstat est distincte : désactiver Webstat ne supprime pas sa clé.
- Les requêtes déjà parties peuvent terminer leur transport ; leur résultat ne remplace pas l’état d’une source désactivée. Les générations empêchent aussi une réponse antérieure à une désactivation/réactivation de réapparaître.
- La première actualisation réussie après reprise établit une référence pour les alertes suspendues, sans envoyer de franchissements rétrospectifs. Les franchissements suivants reprennent normalement. Cet état persiste après relancement.
- Une sélection sans source active est valide. Les caches restent consultables ; aucune source n’est interrogée depuis Explorer.

### Équivalences vérifiées

Le premier rapprochement porte sur les taux de change de référence au comptant BCE diffusés à la fois par Webstat (`EXR.<clé>`) et le service BCE (`ECB:EXR`, version `1.0`). Les clés complètes, le producteur `4F0`, la fréquence, la devise, le type `SP00`, le suffixe `A` et l’échelle zéro doivent concorder. Les titres, traductions ou valeurs identiques ne constituent jamais une preuve d’équivalence.

Un seul repère apparaît dans la sélection et les favoris ; l’ordre existant détermine le représentant, sans préférence automatique pour Webstat ou la BCE. Les deux accès figurent dans « Source et définition ». Ajouter l’autre accès ne crée pas de second repère. Un choix explicite « Utiliser cette source » peut remplacer l’accès, en conservant position, favori, UUID, seuil et état des règles. Les historiques de deux accès ne sont pas fusionnés silencieusement.

Les fréquences, devises, échelles, producteurs et versions différents restent distincts. Les autres familles ne sont pas rapprochées tant qu’une correspondance officielle n’a pas été vérifiée. Ce mécanisme n’est donc pas une garantie d’absence de tout doublon dans les huit catalogues. Les règles déjà distinctes restent distinctes.

### Profil

Prénom, nom et photo sont facultatifs et locaux. La sidebar montre la photo ou les initiales, puis le nom et « Mon espace ». Aucun compte, authentification, envoi ni synchronisation n’est ajouté.

La photo est choisie avec le sélecteur macOS, limitée à 25 Mo à l’entrée, redimensionnée et recadrée au centre en JPEG sRGB de 384 × 384 px. Le fichier d’origine n’est pas modifié. Une nouvelle image est encodée sans les métadonnées EXIF/GPS. Sa petite représentation est enregistrée avec le profil dans les préférences atomiques ; « Retirer » enlève ces octets du document courant. L’app ne réécrit pas les éventuelles sauvegardes faites par le système ou l’utilisateur.

`profile`, `disabledSourceIDs` et `alertBaselineIDs` sont des champs optionnels des préférences v2. Leur absence garde le comportement par défaut. Un fichier illisible n’est jamais remplacé.

### Soutien

« Soutenir sema » ouvre `https://ko-fi.com/antoineberjoan`, depuis À propos et le menu sema. Aucun widget, suivi ou paiement embarqué. Texte : « sema est gratuite. Vous pouvez soutenir son développement sur Ko-fi. »
