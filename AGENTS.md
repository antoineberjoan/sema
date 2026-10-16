# Instructions du projet Sema

Lire `docs/PRODUCT.md`, `docs/ARCHITECTURE.md` et les fichiers concernés avant de modifier le code. Respecter le socle comportemental donné par Antoine ; ces règles le précisent.

## Périmètre et structure

- Nom de l’app : **Sema**. Dépôt : **antoineberjoan/sema**.
- Cible : macOS 14+, Swift 6. Interface native SwiftUI ; AppKit seulement pour un comportement macOS précis.
- Le cœur `MarketCore` reste indépendant de SwiftUI, AppKit et UserNotifications.
- L’interface est rangée par fonctionnalité dans `SemaMac/Features`. Le panneau et la fenêtre partagent `AppStore`.
- Ne pas ajouter de framework d’architecture, de cible, de service serveur ou de dépendance de production sans nécessité explicite et accord préalable pour une dépendance.
- Préférer les composants natifs Apple. Centraliser les choix visuels réutilisés dans `DesignSystem`.
- Respecter Interface Craft dans l’app et ses supports : hiérarchie nette, couleur intentionnelle, profondeur par ombres discrètes, cohérence des espacements et conventions natives. Consulter la skill et `docs/IDENTITY.md` avant une modification de design ou de mouvement.
- Les animations ont des constantes nommées, restent interruptibles et respectent Réduire les animations. Valider le flux au clavier et le rendu natif ; distinguer ce qui est observé de ce qui reste à vérifier.

## Données et calculs

- Toute série porte son origine, sa source, son unité et la date de ses observations.
- Ne jamais présenter une fixture ou un fonds fictif comme une donnée de marché.
- Les devises BCE sont des taux de référence publiés, pas des cours de trading en direct.
- Utiliser `Decimal` pour les valeurs et variations financières. Convertir en `Double` seulement pour la représentation graphique.
- Variation d’un taux : points de pourcentage. Variation d’une VL ou d’une parité : pourcentage relatif.
- Une alerte identifie une part et une devise par `seriesID`. Ne pas agréger différentes parts d’un fonds.
- Une alerte « supérieure à » exige un franchissement strict. La même observation ne doit pas déclencher deux fois.
- Les calculs et le décodage se testent dans `MarketCoreTests`.
- Ne pas intégrer de clé fournisseur partagée dans l’app ou le dépôt.

## État et persistance

- Les mises à jour de l’état UI se font sur le `MainActor`.
- Les favoris et alertes sont locaux, versionnés et écrits atomiquement.
- Ne pas effacer ou réinitialiser silencieusement un fichier de préférences illisible.
- Les notifications système restent désactivées tant que l’utilisateur ne les active pas.
- La démonstration des alertes n’est pas un service de surveillance. Ne pas promettre de surveillance quand l’app est quittée ou le Mac en veille.

## Validation

- Exécuter `./scripts/check.sh` après une modification fonctionnelle.
- Exécuter `./scripts/build-app.sh` pour valider un bundle `.app`.
- Après une modification UI, vérifier le flux concerné dans l’app native : sélection, favoris, historique ou alerte.
- Ne pas installer de dépendance uniquement pour un test de présentation.
- Mettre à jour la documentation lorsqu’un contrat, une source ou le périmètre réellement disponible change.
- Langue de l’interface et des documents : français. Identifiants Swift : anglais.
