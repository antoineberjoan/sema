# Fondation

Ce document dit ce qu'est sema, pour une personne qui ne l'a jamais vu.

## Nom

**sema**, toujours en minuscules dans les textes visibles.

## Raison d'être

Avant, un professionnel du patrimoine suit ses repères économiques (taux, inflation, devises) sur plusieurs sites. Il perd du temps et ne voit pas toujours d'où vient un chiffre.

Après, ses repères tiennent dans une app Mac. Chaque série garde son origine, sa source, son unité et ses dates d'observation. L'app prévient quand un repère sort de l'habituel et rappelle les faits datés de la séance.

## Pour qui

sema sert un professionnel du patrimoine qui lit des sources publiques et veut être prévenu vite, sans disperser son attention.

sema ne sert pas à trader. Les données suivent la fréquence de leurs producteurs : ce ne sont pas des cotations garanties en temps réel, et les devises de la BCE sont des références publiées, pas des cours en direct.

## Périmètre

Dedans :
- consulter des séries issues de sources publiques (Webstat, BCE, Insee, autres producteurs) et de fournisseurs de cours à clé personnelle ;
- suivre des favoris dans une fenêtre et dans un bandeau accessible depuis la barre de menus ;
- définir des seuils, surveiller les mouvements inhabituels, lire le contexte d'une séance et le brief du matin ;
- garder préférences et cache sur le Mac.

Dehors : un service serveur, la synchronisation entre appareils, une clé fournisseur partagée, une promesse de surveillance quand l'app est quittée. Le détail du produit est dans [PRODUCT.md](PRODUCT.md).

## Principes

- Une série affiche toujours son origine, sa source, son unité et ses dates. Une valeur inventée n'existe pas.
- Les valeurs et variations financières se calculent en `Decimal`. Le calcul ne vit jamais dans une vue.
- Les données de la personne restent sur son Mac. Une clé personnelle vit dans le Trousseau, jamais dans le dépôt, une URL, un cache ou un journal.
- Un fichier que la personne a déjà sur son disque est un contrat : ses noms, ses clés et ses valeurs ne changent pas.
- L'interface est native : SwiftUI, AppKit pour un comportement précis, aucune dépendance de production sans accord.
- Une notification reste désactivée jusqu'au choix de la personne.

## Marque

sema doit sembler calme et précise. Les surfaces suivent l'apparence du système ; la valeur et son graphique passent d'abord.

La marque tient en cinq couleurs : Encre, Graphite, Papier, Brume et Sarcelle Profonde (les ancres de `Resources/Brand/tokens.json`). La personne choisit sa palette dans les réglages, parmi sept (la marque et six autres) ; chaque palette redistribue les valeurs des mêmes rôles. L'icône est dans `Resources/Brand/`. La typographie est celle du système (SF Pro). Les jetons de couleur, de forme, d'espace, de texte et de mouvement viennent de `Resources/Brand/tokens.json`, source unique ; `Sources/SemaDesign/` en est la sortie Swift, et le kit de marque téléchargeable (`site/dist/brand/tokens.json`) en est la sortie JSON résolue. Les choix de direction visuelle sont des décisions datées dans `docs/decisions/`.

## Voix

- **Montré** : oui
- **Signature** : sema
- **Publics** : les personnes qui suivent des repères économiques, les contributeurs du dépôt
- **Ton** : calme, précis, sans phrase de remplissage ; direct, posé et concret. Vouvoiement, phrases courtes, vocabulaire financier expliqué. Chaque chiffre porte sa source, sa période et son unité. Une hausse de taux n'est pas toujours une bonne nouvelle : couleur neutre et variation signée.
- **Qualités** : calme, précision, attention aux détails.
- **Mots** : repère, série, source, seuil, séance. On évite « temps réel », que les données ne garantissent pas.
- **Jamais** : une cause économique inventée, un suivi quand l'app est quittée, une valeur que la source n'a pas publiée.
