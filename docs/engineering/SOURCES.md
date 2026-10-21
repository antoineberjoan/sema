# Sources d’autorité

Cadre harmonisé le 21 octobre 2026 selon la règle transverse confirmée par Antoine dans le chat et consignée dans [Équipe](https://app.notion.com/p/3fbd18bb0dea81c9b117c11a249e57df). Notion pilote les objectifs, les priorités, l’organisation, le suivi et toutes les décisions, y compris techniques ; GitHub les implémente par le code, la configuration et les preuves. Les pages Notion sont des décisions et intentions humaines ; leur statut natif « non vérifié » ne constitue ni une approbation ni un rejet. Lire le contenu et l’arbitrage explicite.

| Sujet | Source canonique | Rôle du dépôt |
| --- | --- | --- |
| Navigation | [Accueil](https://app.notion.com/p/f56d18bb0dea83c198de015cb4e36319) | Ce répertoire de liens |
| Vision, public, business, priorités | [Stratégie](https://app.notion.com/p/3fbd18bb0dea819bad4bc31bca0ad436) | Conséquences techniques d’une décision validée |
| Périmètre souhaité, retours | [Produit](https://app.notion.com/p/3fbd18bb0dea81c7add6f4a31d033296) | `PRODUCT.md` décrit le contrat implémenté, pas une seconde roadmap |
| Marque, ton, copy, choix visuels | [Marque](https://app.notion.com/p/3fbd18bb0dea818fa7f4fc7483c767b3) | `IDENTITY.md`, assets et tokens appliquent les décisions |
| Organisation, conventions et décisions techniques | [Équipe](https://app.notion.com/p/3fbd18bb0dea81c9b117c11a249e57df) | `AGENTS.md`, conventions, architecture et contrôles appliquent les décisions |
| Priorités, suivi technique et livraison | [Équipe](https://app.notion.com/p/3fbd18bb0dea81c9b117c11a249e57df), puis page Notion propriétaire du chantier | [GitHub sema](https://github.com/antoineberjoan/sema) porte code, tests, plans de réalisation et PR reliés à cette source |
| Données économiques | Producteur officiel référencé dans `DATA-SOURCES.md` | Décodage et calcul ; ne pas réécrire la définition officielle |

Le business plan n’est pas encore établi dans les pages consultées. Ne pas inventer prix, revenus ou décision de monétisation. Les retours et leur qualification restent suivis dans Notion. Une issue GitHub peut porter leur réalisation et renvoyer à cette source, sans créer un second backlog ni recopier les informations personnelles.

## Passage de l’intention à la réalisation

Une issue, une PR, un plan de réalisation ou une note d’architecture identifie la page Notion source, sa date de lecture, la décision retenue et les critères observables. Toute nouvelle décision durable, y compris technique, se consigne dans cette page avant sa mise en œuvre ; une demande explicite d’Antoine autorise sa réalisation courante et les choix ordinaires restent autonomes. Un lien vers un bloc ou une courte citation de décision suffit ; ne pas exporter tout Notion dans le contexte ou dans Git. Une référence datée décrit un état consulté, elle ne remplace pas la page vivante.

À la livraison, Git garde la preuve et le comportement effectif. La page Notion propriétaire reçoit l’état utile du chantier, les arbitrages et les liens vers ces preuves. Les plans et notes du dépôt décrivent la réalisation, sans fixer une décision concurrente. Pas de synchronisation bidirectionnelle automatique ni de copie de backlog.

Si Notion est inaccessible, poursuivre une correction technique à contrat inchangé à partir des sources locales en signalant cette limite. Une nouvelle décision durable non couverte, y compris technique, reste en attente d’Antoine ou du rétablissement de la page Notion propriétaire. Un agent ne crée pas une vérité de remplacement.

## Divergences

Présenter les deux versions, leur source et leur impact ; demander **la version à garder** avant d’aligner. Ne pas déduire une priorité de la date ou de l’existence de code. Les écarts en cours d’arbitrage sont consignés dans le plan du chantier, pas recopiés ici.
