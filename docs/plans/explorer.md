# Explorer simple et lisible

Statut : implémenté pour revue, 17 octobre 2026, branche `codex/ribbon-signature`.

Source : demande d’Antoine dans le chat du 17 octobre et pages Notion [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296) et [Marque](https://app.notion.com/p/3fbd18bb0dea818fa7f4fc7483c767b3), consultées le même jour. Explorer doit révéler la richesse disponible tout en restant intuitif et simple, sans phrases de remplissage ni actions répétées.

## Résultat attendu

- À l’ouverture, voir les sources actives et leur domaine, y compris sans clé Webstat ; chaque catalogue reste entier et appartient à son fournisseur.
- Dans une source, donner le premier rôle à la recherche, aux résultats et à leur aperçu. Revenir aux sources en une action.
- Supprimer le pied de page décoratif d’Explorer et les accès répétés à la connexion. Conserver les erreurs et leurs actions de reprise au bon endroit.
- Montrer les filtres et codes exacts à la demande. Garder le choix explicite des dimensions, l’aperçu avant ajout et toutes les règles d’unité et de source.
- Utiliser les mêmes contrôles dans Explorer et la recherche rapide ; aucune dépendance, migration, nouvelle requête globale ni calcul financier.

## Preuves et limites

- Bundle release construit, signature stricte valide ; garde-fous, diff et 17 tests Python réussis. La suite Swift locale manque du module `Testing` dans les Command Line Tools ; la CI macOS de la branche vérifie ces tests et le bundle.
- Revue native dans un bundle et un profil séparés, sans clé ni préférence habituelle : huit sources visibles, aucun pied de page redondant, catalogue Insee réel en cache (244 jeux), recherche « loyers » donnant deux jeux, flèches et Entrée ouvrant le premier. Les dimensions sont téléchargées depuis Insee ; recherche « IRL » dans leur sélecteur puis validation par Entrée observées.
- Le code exact est masqué par défaut puis accessible par son volet ; retour aux sources en une action. Webstat sans clé présente une seule connexion ; cette action ouvre Sources et son champ protégé existant. Aucune clé saisie, aucune série ajoutée ni donnée de production modifiée pendant la revue.
- Capture `sema-explorer-sources.png` dans les artefacts du chat. Le mode clair a été choisi dans le seul profil temporaire, mais le contrôle natif a ensuite expiré après fermeture des réglages. Le rendu clair, le format compact de ⌘K, la reprise d’erreur et l’ajout final restent non observés dans cette revue. Le code partagé conserve les règles d’aperçu et d’ajout existantes.

La consigne durable d’Antoine sur simplicité et absence de remplissage est enregistrée dans Marque. Aucun changement de dépendance, de données ou de préférences habituelles, aucune fusion main ni release dans ce lot.
