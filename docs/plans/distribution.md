# Téléchargement et premier lancement de sema

16 octobre 2026. Plan d’implémentation. Le parcours, le DMG et Homebrew sont approuvés. La section de validation de livraison distingue les essais locaux et les accès publics.

## Direction retenue

Le signe D3 accompagne trois moments : comprendre le geste sur le site, installer sema dans Applications, puis choisir ses premiers repères. L’expérience est brève et soignée. Un utilisateur pressé peut toujours accéder immédiatement à l’action utile.

L’app reste native en SwiftUI. La landing conserve HTML, CSS et JavaScript. Les animations web utilisent les capacités du navigateur ; aucune dépendance de production supplémentaire n’est prévue.

## Page de téléchargement

Préparer une page `/download/` dans la continuité de la landing : police système, espace généreux, fond neutre, accent sarcelle. Un bouton principal « Télécharger sema » est accompagné de la version, de la taille, de macOS minimum et de l’architecture réellement disponible.

Le bundle actuel est arm64 et cible macOS 14+. La première version téléchargeable sera annoncée pour les Mac avec puce Apple. Ajouter une version Intel ou universelle seulement après compilation et vérification sur cette architecture ; ne pas déduire la compatibilité de la seule version de macOS.

Sous le bouton, un lien textuel « Installer avec Homebrew » ouvre un petit bloc de commande avec copie et confirmation accessible. Il ne concurrence pas visuellement le téléchargement direct. Le bouton de copie n’apparaît qu’avec une commande réellement opérationnelle.

La page présente les étapes « Ouvrez le fichier », « Glissez sema dans Applications », « Ouvrez sema ». Une démonstration animée du geste est rejouable. Elle n’est ni une progression réelle du téléchargement ni une preuve que l’installation a réussi. Le lien de téléchargement reste disponible si JavaScript échoue.

## DMG personnalisé

Le [format DMG](https://support.apple.com/en-ca/guide/disk-utility/dskutl11888/mac) monte une image disque dans le Finder. Des outils de packaging permettent de configurer son fond et la disposition des icônes ; [create-dmg](https://github.com/create-dmg/create-dmg) documente ces possibilités.

Retenir un fond statique dessiné pour cette fenêtre. La personnalisation du Finder ne doit pas être confondue avec une fenêtre SwiftUI capable d’animer les gestes librement. Les interactions animées sont réalisées sur le site et dans l’accueil natif.

### Composition Le fil

- Cible de départ : fenêtre de contenu 640 × 400 pt, fond papier clair `#F5F6F3`. Les vrais noms noirs du Finder restent ainsi lisibles dans les deux apparences de macOS. Préparer une image Retina et vérifier son échelle dans le Finder.
- Icône sema à gauche et raccourci vers le véritable dossier Applications à droite, alignés sur le même axe. Icônes indicatives de 96 pt ; positions à régler dans la fenêtre réelle.
- La courbe Palier — Référence forme un chemin discret entre les deux icônes, avec un indice de direction clair. Les noms et les cibles restent reconnaissables.
- Titre « Faites une place à vos repères. » puis instruction « Glissez sema dans le dossier Applications. » Le geste ne dépend pas du slogan.
- Aucun contrôle dessiné qui ressemble à un bouton actif. Ni faux pourcentage de copie, ni effet décoratif masquant les fichiers ou la destination.

Le packaging sera reproductible et distinct de `build-app.sh`. Il prend un bundle validé et un numéro de version, fabrique un volume temporaire, ajoute le lien Applications et le fond, fixe la présentation, puis produit un DMG compressé en lecture seule et son SHA-256. Les volumes temporaires sont démontés même en cas d’erreur.

Choisir l’outil de packaging après un essai local. Préférer les outils macOS présents ; si un outil tiers est nécessaire, le figer comme outil de construction et documenter son rôle. L’outil ne doit pas devenir une dépendance de l’app.

## Accueil natif

L’accueil s’affiche seulement au premier lancement ou sur demande depuis les réglages. Un utilisateur existant conserve ses préférences et entre directement dans son espace. L’état d’accueil est local et versionné ; quitter pendant une étape ne détruit aucune sélection.

1. **Vos premiers repères.** Une courte apparition du signe, un titre et quatre collections — Taux & marchés, Économie réelle, Épargne et Devises. Les 13 repères se choisissent par pastilles, sans défilement ni bordure décorative. Les repères recommandés sont modifiables ; on peut poursuivre sans en choisir ou ouvrir ensuite le catalogue complet. Aucun carrousel de présentation obligatoire.
2. **Vos données Webstat.** Expliquer comment obtenir et connecter sa clé personnelle. Réutiliser la validation et le stockage dans le Trousseau. Proposer « Découvrir en démonstration » ; un refus réseau conserve la saisie en mémoire et permet de réessayer ou de passer.
3. **Arrivée dans l’espace.** Les choix apparaissent dans la liste de repères, avec une brève transition de continuité. Si l’on a choisi la démonstration, les données fictives restent signalées. La permission de notifications est demandée au moment de créer une alerte, avec une action explicite.

Le lien « Passer » est visible. Les boutons sont utilisables pendant les transitions. Tester le lancement depuis le DMG, depuis Applications et via Homebrew : même accueil, sans copie automatique surprise de l’app et sans demande administrateur ajoutée par sema.

## Storyboards et réglage des animations

Les valeurs suivantes sont des points de départ sema à régler dans les prototypes. Elles seront regroupées dans des constantes nommées, avec une séquence d’états lisible et l’annulation des animations à la fermeture.

| Moment | Séquence initiale | Accessibilité et interruption |
| --- | --- | --- |
| Démonstration web | 0 ms : composition visible. 120–480 ms : la courbe se dessine. 480–900 ms : l’icône suit le chemin. 900–1080 ms : la destination s’accentue puis revient au repos. | Une seule lecture, bouton Rejouer. Réduire les animations : trois étapes statiques. Aucun blocage du téléchargement. |
| Accueil natif | 0–360 ms : dessin du signe. 120–300 ms : titre et contenu apparaissent, déplacement maximal 6 pt. | Actions visibles dès le début. Si interrompu, état final cohérent ; pas de reprise systématique de l’introduction. |
| Choix d’un repère | Confirmation immédiate ; ajustement visuel amorti sur 160–220 ms. | Aucun saut de ligne pendant la sélection ; état annoncé à VoiceOver. |
| Entrée dans l’espace | Transition de 220–280 ms de la sélection vers la liste principale. | Focus déplacé vers le premier repère ou l’état vide ; sans vol d’icônes si Réduire les animations. |
| Copier Homebrew | Le libellé passe à « Copié », puis revient après un court délai. | Échec du presse-papiers explicite ; commande sélectionnable manuellement. |

Un panneau de développement règle durée, amortissement, distance et ombres en temps réel. Les clics répétés remplacent l’animation courante depuis son état visible. Tester au clavier, au trackpad et pendant une saisie rapide. Le panneau de réglage n’est pas livré à l’utilisateur.

## Homebrew et hébergement

Créer un cask dans notre propre tap, suivant la [documentation Homebrew](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap). Le cask contient version, URL HTTPS du fichier versionné, SHA-256, architecture, macOS minimum et `app "Sema.app"`. Le [Cask Cookbook](https://docs.brew.sh/Cask-Cookbook) décrit ce format.

Proposition de dépôt de distribution : `antoineberjoan/homebrew-sema`, avec le cask et les fichiers de version publiés en Releases. Le code source de `antoineberjoan/sema` reste privé. La commande envisagée serait `brew install --cask antoineberjoan/sema/sema` ; elle ne doit être affichée comme utilisable qu’après création du dépôt et test effectif.

Le site sema actuel est privé. Un visiteur non connecté et Homebrew ne peuvent pas dépendre de cette session pour obtenir le DMG. Il faut donc choisir et vérifier l’audience du site et du dépôt de distribution au moment de publier. Les artefacts privés de test précèdent cette ouverture ; aucun jeton GitHub ou clé Webstat ne doit être transmis aux téléchargeurs.

Chaque version possède une URL immuable, une empreinte et des notes de changement. Le même DMG sert au site et au cask. Tester une installation fraîche et `brew upgrade` d’une version précédente. L’auto-mise à jour dans l’app reste un chantier séparé.

## Distribution sans abonnement Apple

La première alpha utilise une signature ad hoc. Une signature Developer ID et la notarisation demandent l’identité de développeur appropriée ; la notarisation est une analyse de sécurité décrite par [Apple](https://developer.apple.com/developer-id/). Sans elle, les utilisateurs peuvent rencontrer le blocage Gatekeeper et devoir autoriser manuellement cette app de confiance dans les réglages, selon [la procédure Apple](https://support.apple.com/fr-fr/102445).

Afficher « Version alpha non notarisée » près du téléchargement et fournir une aide courte avec captures de la version macOS testée. Homebrew ne contourne pas cette étape. Aucun script ne désactive Gatekeeper ou ne retire silencieusement la quarantaine.

## Validation avant activation du téléchargement

- Compiler une version propre, versionner `CFBundleShortVersionString` et `CFBundleVersion`, vérifier architecture, signature et macOS minimum. Le bundle ne contient ni `SemaDevelopmentDataDirectory`, ni cache personnel, ni clé.
- Ouvrir le DMG dans le Finder en affichage standard et Retina ; contrôler la taille, les icônes, le fond, les libellés et le glisser vers Applications. Tester réouverture et copie après éjection.
- Télécharger réellement par navigateur sur un autre compte ou Mac afin de reproduire la quarantaine. Ne pas confondre le succès du bundle local avec l’expérience d’un téléchargement Internet.
- Vérifier premier lancement, parcours passé, reprise après fermeture et lancement suivant. Les favoris et la clé survivent à une mise à jour.
- Tester le lien sans session développeur, le SHA-256, l’installation Homebrew, la mise à jour et la désinstallation sans supprimer les données utilisateur par défaut.
- Vérifier sur la page les versions desktop/mobile, le clavier, le focus, Réduire les animations, JavaScript absent, un clic répété et une animation interrompue.
- Mettre à jour landing et FAQ uniquement pour les fonctionnalités effectivement livrées. Présenter séparément ce qui reste en développement.

## Livrables

Un prototype de page de téléchargement et ses réglages de mouvement ; un fond DMG et un script reproductible ; un accueil natif réutilisant la connexion et les préférences ; un DMG versionné et son empreinte ; un cask testé ; les captures de validation et une courte aide d’installation.


## Point de reprise — contraste de la sidebar, 17 octobre 2026

**État : version locale 0.5.2 validée ; publication en attente d’accord explicite.** Source : demande d’Antoine dans le chat, « meilleur contraste sur la sidebar ». Le commit `d7442e768d9d76e5f3ae7705a12229b7e84b6af7` est sur `origin/main`. La sidebar utilise le texte primaire pour les actions, un gris opaque clair/sombre pour les valeurs secondaires et une sélection plus présente. La matière native et le comportement de survol sont conservés. Les preuves de parcours natif et la CI macOS sont dans [sidebar-0.5.2.json](../validation/sidebar-0.5.2.json).

Le bundle local `dist/Sema.app` est mis à jour, build 16. Le DMG préparé est `dist/releases/0.5.2/Sema-0.5.2-arm64.dmg` ; la signature et l’image disque sont vérifiées. Le code du bundle de revue resigné correspond au code de production. Aucune préférence personnelle n’a été remplacée.

Le contrôle automatique a refusé la création de la release publique et l’actualisation du visuel du site, jugeant l’autorisation antérieure insuffisante pour cette nouvelle version. Ne pas relancer ces actions avant une réponse explicite d’Antoine. Le manifeste publié, Homebrew et le téléchargement du site restent en 0.5.1.

Après accord : publier ce DMG et son SHA-256 dans `antoineberjoan/homebrew-sema`, vérifier le téléchargement sans authentification, mettre à jour et tester le cask public (installation et 0.5.1 → 0.5.2), puis synchroniser `distribution/release.json` avec `scripts/distribution/sync-download.py`. Actualiser le visuel seulement si l’accord le couvre. Préserver les changements du socle agentique apparus en parallèle : ils ne font pas partie du correctif de contraste.

### Ajustement local de la sidebar — 17 octobre

La branche distante `codex/sidebar-spacing` (`e4ca175`) retire l’engrenage du hub et ramène la marge supérieure de recherche à 8 pt. Bundle local recompilé, signé et ouvert depuis `dist/Sema.app` ; profil, ⌘K, fermeture/réouverture et périodes vérifiés dans le natif. Les garde-fous et leurs 12 tests passent ; les tests Swift restent bloqués localement par le module `Testing` absent. La CI du commit de contraste ne couvre pas cet ajustement. Le DMG 0.5.2 déjà préparé doit être reconstruit depuis le code retenu avant toute publication autorisée ; son ancien hash reste celui de l’artefact existant.
