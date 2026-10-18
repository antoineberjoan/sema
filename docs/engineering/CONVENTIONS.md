# Conventions de code

Ces règles servent une lecture directe du code. Une règle mécanique appartient à `scripts/guardrails.py` ; une question de sens appartient à la revue. Ne pas créer de contrôles approximatifs qui bloquent du code correct.

## Une responsabilité, un emplacement

La carte exécutable est [structure.json](../../.agents/structure.json). Placer une vue dans la fonctionnalité qu’elle sert, un calcul pur dans le cœur, un effet système dans l’infrastructure. Centraliser un composant uniquement lorsque plusieurs usages partagent réellement son contrat. Pas de dossiers `utils`, `misc`, `common` ou de framework interne par anticipation. Le nom d’un type suffit à retrouver son fichier : `guardrails.py` refuse un second type visible dans un fichier et un fichier d’extensions mal nommé. Découper un type volumineux en extensions `Type+Rôle.swift` oblige à rendre `internal` les membres partagés entre ces fichiers ; le faire seulement quand le gain de lecture le justifie.

Avant d’ajouter un fichier, pouvoir écrire sa responsabilité en une phrase. Cette phrase ouvre le fichier, après le shebang, la directive SwiftPM ou le doctype si nécessaire. Conserver un descriptif existant utile ; pas d’auteur, de date de session, de récit des changements ou de commentaire qui répète le nom du fichier. JSON, images et autres formats sans commentaire n’ont pas d’en-tête artificiel.

## Noms et duplication

Le [glossaire](GLOSSARY.md) fixe le vocabulaire métier partagé. `seriesID` désigne le même concept dans une vue, un calcul et une frontière JavaScript éventuelle. Respecter les noms imposés par `Identifiable`, Codable, une API ou un schéma publié ; traduire à la frontière au lieu de créer des synonymes partout.

Une fonction décrit une action ; un booléen une condition. Préférer `load`, `save`, `isEnabled` dans un contexte explicite à une abréviation obscure ou à un nom qui répète tout le type. Deux valeurs distinctes dans la même portée doivent rester distinctes : `publishedSeries` et `displayedSeries` ont un sens différent.

Supprimer les anciens appelants et l’ancienne implémentation lors d’un remplacement. Pas de wrapper d’alias pour conserver un ancien nom, pas de code commenté « au cas où ». Les synonymes de recherche utilisateur et les termes imposés par une API système ne sont pas des alias d’architecture.

Zéro duplication de connaissance : un contrat métier possède un propriétaire. Deux lignes similaires ne justifient pas à elles seules une abstraction. Les copies de livraison sont admissibles seulement avec une source désignée et une vérification de cohérence ; `distribution/release.json` fait foi pour son miroir web.

## Constantes et configuration

| Valeur | Propriétaire |
| --- | --- |
| Règle métier, seuil technique motivé, limite d’un fournisseur | Type ou client portant le contrat, constante nommée et test utile |
| Couleur, espacement partagé, composant réutilisé | `DesignSystem` ; tokens CSS pour le site |
| Durée, ressort ou distance d’une séquence | Constantes de mouvement nommées près de la séquence |
| Choix personnel | Modèle de préférences et persistance existants |
| Environnement, URL publique de configuration | Configuration du bundle ou de l’outil propriétaire |
| Secret | Trousseau ou environnement autorisé, jamais le dépôt |

Dans l’app, aucune valeur visuelle n’est écrite dans l’appel : rayon, police, trait, durée, ressort, marge, espacement, cadre, opacité, décalage, approche, nombre de lignes et échelle minimale se nomment dans un rôle de `SemaTheme` ou un `static let` de leur propriétaire. `guardrails.py` le refuse, ternaires compris ; `0` et `1` restent permis. Une police reprend le style de texte natif quand sa taille existe (`.body`, `.callout`, `.subheadline`…), une ombre est une `SemaTheme.Shadow`, une touche une constante Carbon `kVK_…`.

Les valeurs partagées vivent dans `SemaTheme` et se nomment par rôle : rayons `rowCorner`, `cardCorner`, `surfaceCorner` ; lignes `rowPadding`, `rowSpacing`, `rowTextSpacing`, `rowTitleLines` ; `contentPadding`, `iconButtonSize`, `selectionOpacity`, `hoverFill`, `quietFill`. Le rythme suit deux unités, `minorSpacing` entre éléments liés et `majorSpacing` entre groupes ; une nouvelle vue part de ces unités. Réutiliser un rôle existant avant d’en créer un. Dans le cœur, une règle métier se nomme sur son type : seuils d’alerte, précision des séries, fenêtre d’historique récente, délais et limites des fournisseurs, versions de schéma.

Une constante se définit une seule fois à la portée utile. Les littéraux structurels évidents (`0`, `1`, collection vide), les valeurs exactes d’un protocole et les fixtures identifiées ne deviennent pas des options de configuration. Une URL de fournisseur peut rester une constante du client : rendre l’hôte configurable sans besoin fragiliserait notamment l’envoi des clés. Ne pas externaliser tous les textes dans un registre générique ; mutualiser ceux qui portent réellement la même copy.

## Une version active et les données existantes

L’objectif est une seule version du comportement métier. Une migration d’entrée qui préserve les données déjà distribuées est une frontière de stockage, pas une deuxième app. Ne pas confondre suppression d’un ancien chemin de code et effacement des préférences d’un utilisateur.

Avant de retirer une migration : établir les versions effectivement distribuées, prouver le chemin de récupération, nommer le coût et faire arbitrer toute perte ou rupture par Antoine. Ne pas ajouter de compatibilité pour une version hypothétique. La sortie de migration est le modèle courant ; les comportements métier restent uniques.

## Revue minimale

Lire les appelants avant de supprimer ; chercher les usages et variantes avant d’ajouter. Vérifier responsabilité, noms, source des constantes, absence d’ancien chemin actif et conservation des données. Le compilateur ne prouve pas l’absence de code mort ; une recherche textuelle ne suffit pas pour les points d’entrée SwiftUI, Codable ou AppKit.
