# Explorer simple et lisible

Statut : accès direct implémenté pour revue, validation native bloquée, 17 octobre 2026, branche `codex/ribbon-signature`.

Source : demande d’Antoine dans le chat du 17 octobre et pages Notion [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296) et [Marque](https://app.notion.com/p/3fbd18bb0dea818fa7f4fc7483c767b3), consultées le même jour. Explorer doit révéler la richesse disponible tout en restant intuitif et simple, sans phrases de remplissage ni actions répétées.

Antoine précise ensuite dans le même chat que choisir de nombreuses dimensions est trop compliqué. Ce retour remplace le formulaire obligatoire par la découverte des séries déjà publiées : recherche par nom, choix d’une série existante, aperçu puis ajout. Les paramètres restent facultatifs dans une recherche avancée. Preuve technique : le jeu Insee de sa capture renvoie 1 401 séries et leurs attributs avec `detail=nodata`, sans observations. [Documentation Insee](https://www.insee.fr/fr/information/2862759), [BCE](https://data.ecb.europa.eu/help/api/data).

## Résultat attendu

- À l’ouverture, voir les sources actives et leur domaine, y compris sans clé Webstat ; chaque catalogue reste entier et appartient à son fournisseur.
- Dans une source, donner le premier rôle à la recherche, aux résultats et à leur aperçu. Revenir aux sources en une action.
- Supprimer le pied de page décoratif d’Explorer et les accès répétés à la connexion. Conserver les erreurs et leurs actions de reprise au bon endroit.
- Présenter les séries réellement publiées après le choix du jeu ; rechercher leur libellé et ouvrir un aperçu en un clic. Les dimensions et le code exact restent dans Recherche avancée, sans combinaison automatique ni téléchargement collectif des observations. Conserver unités, sources et règles d’ajout.
- Utiliser les mêmes contrôles dans Explorer et la recherche rapide ; aucune dépendance, migration, nouvelle requête globale ni calcul financier.

## Preuves et limites

- Bundle release construit, signature stricte valide ; garde-fous, diff et 17 tests Python réussis. La suite Swift locale manque du module `Testing` dans les Command Line Tools ; la CI macOS de la branche vérifie ces tests et le bundle.
- Revue native dans un bundle et un profil séparés, sans clé ni préférence habituelle : huit sources visibles, aucun pied de page redondant, catalogue Insee réel en cache (244 jeux), recherche « loyers » donnant deux jeux, flèches et Entrée ouvrant le premier. Les dimensions sont téléchargées depuis Insee ; recherche « IRL » dans leur sélecteur puis validation par Entrée observées.
- Le code exact est masqué par défaut puis accessible par son volet ; retour aux sources en une action. Webstat sans clé présente une seule connexion ; cette action ouvre Sources et son champ protégé existant. Aucune clé saisie, aucune série ajoutée ni donnée de production modifiée pendant la revue.
- Capture `sema-explorer-sources.png` dans les artefacts du chat. Le mode clair a été choisi dans le seul profil temporaire, mais le contrôle natif a ensuite expiré après fermeture des réglages. Le rendu clair, le format compact de ⌘K, la reprise d’erreur et l’ajout final restent non observés dans cette revue. Le code partagé conserve les règles d’aperçu et d’ajout existantes.

La consigne durable d’Antoine sur simplicité et absence de remplissage est enregistrée dans Marque. Aucun changement de dépendance, de données ou de préférences habituelles, aucune fusion main ni release dans ce lot.


## Accès direct — preuves et vérifications restantes

Cinq tests supplémentaires couvrent les métadonnées sans observations, la cohérence d’identifiant avec l’historique, les clés incomplètes, pieds de réponse tronquée, doublons contradictoires et entités XML, les routes sans clé et les sélections New York/Banque mondiale. Les très gros catalogues échouent explicitement après 20 Mio au maximum, sans liste partielle, avec l’accès avancé disponible.

Le bundle de revue compile et sa signature stricte est valide. Un programme de contrôle lié au cœur effectivement compilé a interrogé le jeu Insee `CNA-2014-CONSO-SI` : 1 401 séries, 11 dimensions résolues chacune, puis deux observations historiques d’une série et son unité indice. Le catalogue conserve les libellés officiels, y compris les séries arrêtées ; aucune observation n’est chargée pour les autres résultats.

L’ouverture du nouvel aperçu par le contrôle natif a expiré après un blocage anormal d’environ 40 minutes. Aucune nouvelle validation visuelle ou interaction native de la liste directe n’est déclarée : recherche par nom, ouverture de l’aperçu, retour à la liste et ajout final restent à vérifier dans ce bundle. Les observations natives de la version précédente ci-dessus ne valident pas ce nouveau parcours. Les autres accès SDMX utilisent le même contrat `nodata`, sans validation exhaustive de tous les jeux. Aucun ajout de dépendance, migration ni publication.

Correction d’arrondi du même chat : le bouton d’alerte utilise maintenant `.buttonBorderShape(.capsule)`. Le rendu capsule, l’ouverture de l’éditeur sur Euro / Dollar et son annulation ont été observés dans le bundle isolé `sema-radius-review.app`, sans enregistrer de règle. Capture `sema-hub-capsule-alert.png` dans les artefacts du chat.
