# Les fichiers écrits par les versions publiées restent lisibles jusqu'à une condition de retrait

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine

## Contexte

Des personnes ont sur leur disque des fichiers écrits par les versions publiées de sema : des préférences de schéma 1, un cache Webstat de schéma 1, le raccourci d'espace de travail ⌃⌥H et des règles d'alerte de fonds. Une lecture qui les refuse efface leurs choix.

## Décision

La relecture est une étape nommée, isolée, avec ses tests. Elle ne se mêle à aucun comportement du produit.

- **Préférences de schéma 1.** `PreferencesMigration.upgrade` (`Sources/MarketCore/Preferences/Schema/`) les fait passer en schéma 2 : identifiants locaux convertis en clés Webstat, règles et points de départ gardés, accueil marqué comme déjà vu. `PreferencesRepository` copie le document d'origine en `preferences.json.v1-backup` avant d'écrire le schéma 2.
- **Raccourci d'espace de travail ⌃⌥H.** La même étape le remplace par la valeur standard. Un choix personnel et une action désactivée restent intacts.
- **Cache Webstat de schéma 1.** `LocalRepository.cachedWebstat` le lit, convertit les identifiants et le réécrit en copiant l'original en `webstat-cache.json.v1-backup`.
- **Règles d'alerte de fonds.** Une règle sans condition garde la variation relative (`AlertRule.effectiveCondition`). Aucun écran n'expose de fonds.

Le test `versionOneUpgradePreservesAlertIdentityCheckpointAndFundFavorites`, le test `migrationIsAtomicAndKeepsOriginalFile` et le test `originalWorkspaceShortcutChangesWithoutReplacingCustomBindings` couvrent l'étape.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Garder l'étape isolée, avec sa condition de retrait | Aucun choix perdu | Un peu de code à retirer plus tard |
| Supprimer la lecture maintenant | Moins de code | Les choix d'une personne qui n'a pas encore ouvert la version publiée sont perdus |

**Recommandation** : garder l'étape. Une migration de format est une décision d'Antoine.

## Conséquences

**Condition de retrait.** Antoine confirme que (1) aucun fichier de schéma 1 ni aucune règle de fonds n'existe sur ses disques et (2) la version publiée qui écrit le schéma 2 est installée chez toutes les personnes concernées. Alors un seul lot supprime `PreferencesMigration`, la branche schéma 1 de `AppPreferences.init(from:)`, la branche schéma 1 de `cachedWebstat`, la catégorie `funds` et `AlertCondition.relativeChange`, avec leurs tests.
