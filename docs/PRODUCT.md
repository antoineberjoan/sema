# Produit et périmètre

## Promesse

Permettre à un professionnel du patrimoine de consulter quelques repères économiques et les fonds qu’il suit, sans disperser son attention entre plusieurs sites.

## Direction retenue

Mélange des maquettes **Panorama** et **Atelier** validé par Antoine : douceur et lisibilité du panneau, structure d’une petite app de travail. Références : Hoy, Helumi, Monocle, Klack et Alcove. L’app reste sobre ; le mouvement sert les changements d’état et les sélections.

Deux surfaces partagent la même information :

1. Panneau dans la barre de menus : accès rapide aux repères et favoris.
2. Fenêtre principale : sélection des séries, historiques, recherche de fonds et gestion des alertes.

## Contrats de la version 0.1

| Fonction | Comportement attendu |
| --- | --- |
| Panorama | Basculer entre Marchés & devises et Épargne & économie ; sélectionner une série et consulter son historique. |
| Origine | Identifier clairement les données de démonstration et les séries BCE réellement téléchargées. |
| Favoris | Ajouter ou retirer un repère ou une part, et retrouver la sélection après relancement. |
| BCE | Actualiser trois parités ; conserver les dernières observations si le réseau échoue ; afficher leur date. |
| Fonds | Rechercher et sélectionner quatre fonds fictifs, chacun avec une part et une devise déterminées. |
| Alertes | Créer une règle de hausse/baisse, la mettre en pause, la supprimer et simuler un franchissement. |
| Notifications | Le test est visible dans l’app ; une notification système est optionnelle après autorisation. |

## Hors de cette version

- Données réelles de fonds et intégration Morningstar.
- Surveillance automatique, exécution en arrière-plan, serveur de notifications.
- Compte utilisateur, synchronisation, abonnement et facturation.
- Widgets de bureau et îlot autour de l’encoche.
- Distribution publique ou bêta client notarialisée.

## Vérification manuelle d’un incrément

1. Ouvrir l’app et le panneau de barre de menus ; sélectionner un indicateur et changer de période.
2. Modifier les favoris dans une surface et vérifier l’autre, puis relancer l’app.
3. Actualiser les devises et contrôler l’origine BCE, la devise de cotation et la date.
4. Sélectionner une part fictive, créer une alerte à 2,5 %, la tester, la mettre en pause puis la supprimer.
5. Contrôler les erreurs réseau et l’absence de perte de préférences.
