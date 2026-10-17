# Accès en fond et ouverture de session

Statut : implémenté en revue, vérification au clavier réel en attente, 17 octobre 2026, branche `codex/ribbon-signature`.

Source : demande d’Antoine dans le chat du 17 octobre : accéder au bandeau avec ⌃⌥B depuis les autres apps, conserver les raccourcis avec le hub fermé et ajouter le lancement automatique dans les réglages. Intention reportée dans [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296).

## Critères observables

- Fermer la dernière fenêtre laisse sema dans la barre de menus ; ⌃⌥B affiche et referme le bandeau depuis une autre app, et le raccourci du hub rouvre sa fenêtre.
- Général propose un seul interrupteur d’ouverture de session, désactivé avant choix de l’utilisateur. L’état vient de `SMAppService.mainApp`, sans copie dans les préférences JSON.
- Activation, désactivation, refus et retour des réglages système reflètent l’état réel ; une erreur reste visible. Aucune relance forcée après Quitter sema.
- Un lancement identifié comme ouverture de session masque la fenêtre initiale sans désactiver le menu, les raccourcis ou l’actualisation quotidienne. Un lancement manuel reste normal.
- Bundle compilé, contrôles du dépôt et parcours natif isolé ; aucune déconnexion de la session d’Antoine pour vérifier le démarrage réel.

## Implémentation

La présence en fond et les deux raccourcis globaux existent déjà : `LSUIElement`, `applicationShouldTerminateAfterLastWindowClosed = false`, contrôleurs conservés par le délégué d’app et enregistrements Carbon. Leur durée de vie ne dépend pas du hub. Quitter sema termine le processus et libère les raccourcis.

Le nouvel effet `Infrastructure/LoginItem.swift` utilise l’API native Service Management, déjà disponible sur macOS 14. Aucun helper, agent séparé, dépendance de package ni enregistrement automatique au lancement. Les réglages lisent à nouveau le statut à leur ouverture et à la réactivation de l’app.

## Preuves

- Garde-fous et 17 tests Python réussis. `check.sh` retrouve la limite locale des chemins de Swift Testing ; les 86 tests Swift passent avec les chemins explicites des frameworks des Command Line Tools. Les scripts et la plist passent aussi leurs contrôles de syntaxe.
- Bundle debug compilé, signature ad hoc stricte valide, profil et identifiant de revue isolés. Le nouveau contrôle est observé dans Général, désactivé initialement ; l’activation passe à l’état natif activé sans erreur, et le statut reste activé au retour dans Général. La désactivation revient à désactivé sans erreur ; le bundle temporaire est donc désinscrit à la fin de l’essai. Aucune adhésion Apple Developer n’a été requise pour cette inscription locale.
- Le profil de revue avait volontairement ses deux raccourcis effacés. Les restaurations ⌃⌥B et ⌃⇧H sont acceptées sans conflit. Le contrôle natif ne déclenche pas les combinaisons système de façon observable ; un essai au clavier réel a été demandé, sans déclarer ce parcours validé.

## Vérifications restantes

Vérifier le raccourci au clavier réel, question envoyée dans le chat. Le véritable prochain login ne peut être observé sans déconnecter la session ; le traitement du lancement de session est compilé mais n’est pas déclaré observé au prochain login. Le statut d’autorisation requise et les erreurs sont traités dans le code, sans avoir été forcés sur le Mac. Aucune release ni fusion main.

Références : [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice), [contrat de register](https://developer.apple.com/documentation/servicemanagement/smappservice/register()), [événement d’ouverture de session](https://developer.apple.com/documentation/coreservices/1556410-launch_apple_event_constants/keyaelaunchedasloginitem).
