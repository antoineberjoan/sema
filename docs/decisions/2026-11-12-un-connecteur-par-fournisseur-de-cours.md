# Un connecteur par fournisseur de cours

Date : 2026-11-12 · Statut : proposée
Décidé par : à confirmer par Antoine (arbitrage de l'architecte du 2026-11-12)

## Contexte

Deux fournisseurs de cours n'ont rien en commun : Twelve Data (clé dans un en-tête, plusieurs points d'accès JSON) et Alpha Vantage (un seul point d'accès, clé dans l'adresse, catalogue en CSV, un appel toutes les 1,1 seconde). Sophos veut un connecteur par service.

## Décision

Deux connecteurs, deux acteurs, chacun avec son décodage dans `Mapping/`.

| Connecteur | Ce qu'il garde en propre |
| --- | --- |
| `TwelveData` | Limite de 8 appels par minute, droits du forfait, catalogue en trois appels |
| `AlphaVantage` | Écart de 1,1 seconde entre deux appels, catalogue CSV, titres de presse |

Ce que les deux partagent est dans `Common/` : l'erreur `MarketDataError`, le transport (session sans cache ni cookie, sans redirection, lecture du code HTTP), la lecture des clôtures et des erreurs publiées avec un code 200, et le protocole `MarketDataConnector`. Les valeurs de départ d'un catalogue restent dans `Series/Model/MarketCatalogue`.

## Options

| Option | Ce qu'elle donne | Ce qu'elle coûte |
| --- | --- | --- |
| Un acteur unique, avec un test de fournisseur dans chaque méthode | Un seul fichier | Une règle de Sophos non suivie ; chaque ajout touche les deux fournisseurs |
| Deux connecteurs, un protocole pour l'app | Un fournisseur se retire d'un bloc ; les titres de presse ne concernent plus que le bon connecteur | Un protocole et une propriété de plus dans `AppStore` |

## Conséquences

`AppStore.marketClients` est un dictionnaire par fournisseur de `any MarketDataConnector`. `AppStore` a aussi `alphaVantageClient`, car les titres de presse ne sont pas dans le protocole : Twelve Data n'en a pas. Les tests suivent leur connecteur.

## Trace

Arbitrage de l'architecte du 2026-11-12.
