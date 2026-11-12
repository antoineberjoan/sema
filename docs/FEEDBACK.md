# Retours utilisateurs

Le bouton « Une idée ou un bug ? » du cartouche ouvre un formulaire public dans le navigateur. Le formulaire est un formulaire Notion : il accepte des réponses, mais il ne donne aucun droit de lecture sur la base qui les reçoit.

- Il demande Sujet, Type (Idée ou Bug) et Description. L'e-mail est facultatif, seulement pour répondre.
- L'URL publique est dans `SemaFeedbackFormURL` de `Resources/Info.plist`. Aucun secret n'est dans l'app ou le dépôt.
- L'app n'envoie rien toute seule : ni données, ni clé Webstat, ni journaux. Si le système refuse d'ouvrir le navigateur, une alerte propose de copier le lien.
- La base des réponses est privée : Antoine seul y a accès.

Vérifié le 16 octobre 2026 avec un retour de test : Sujet, Type et Description sont arrivés dans la base privée. Les réglages de partage n'ont pas été revérifiés depuis.
