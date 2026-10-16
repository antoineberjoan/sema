# Retours utilisateurs

## Destination

- [Accueil de l’espace sema](https://app.notion.com/p/f56d18bb0dea83c198de015cb4e36319) : privé, Antoine seul membre et propriétaire.
- [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296) : périmètre et accès au suivi.
- [Retours sema](https://app.notion.com/p/22a9073ae8dd47c9b82a8460e6bbe970) : base privée, vues « Tous les retours » et « Suivi ».
- [Formulaire public](https://antoineberjoan.notion.site/5e95023c58754a8990fd16f5fd1ad5f2) : uniquement dépôt de réponse, sans connexion ni droit de lecture sur la base.

Le formulaire demande Sujet, Type (Idée / Bug) et Description. L’e-mail est facultatif, uniquement pour répondre. Statut et date de réception restent internes. Après envoi : « Merci pour votre retour. Il nous aide à améliorer sema. » Aucun lien « Afficher ma réponse » n’est proposé.

## App

`Resources/Info.plist` porte l’URL publique dans `SemaFeedbackFormURL`. Aucun secret Notion n’est nécessaire. Le bouton natif du cartouche ouvre le navigateur via AppKit ; l’app ne transmet pas automatiquement ses données, sa clé Webstat ou ses journaux. Si le système refuse l’ouverture, une alerte permet de copier le lien.

## Vérification

Le 16 octobre 2026, un retour explicitement nommé « Test technique · formulaire sema » a été envoyé sur le domaine public Notion, sans e-mail. Sujet, Type et Description ont été retrouvés dans la base privée avec le statut « À lire ». Ce retour de test a ensuite été classé « Terminé ». La confirmation publique n’expose pas de réponse.

Les droits de la base restent « Uniquement les personnes invitées » ; le teamspace est privé, avec un seul membre et Antoine propriétaire. Seul le réglage du formulaire est « Tout internaute disposant d’un lien », avec réponses anonymes.
