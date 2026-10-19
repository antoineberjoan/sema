# Sécurité

## Signaler une vulnérabilité

Utiliser le [signalement privé GitHub](https://github.com/antoineberjoan/sema/security/advisories/new). Ne pas ouvrir d’issue publique contenant une méthode d’exploitation, une clé ou des données personnelles. Si ce canal est indisponible, contacter le mainteneur à l’adresse publique `antoineberjoan@gmail.com`.

Indiquer la version de sema et de macOS, le comportement observé, l’impact possible et une reproduction minimale avec des données fictives. Ne jamais transmettre de véritable clé API. Le mainteneur examinera le signalement ; aucun délai de réponse garanti n’est annoncé.

## Versions et distribution

Les corrections visent la dernière version publiée. Aucune maintenance des anciennes versions n’est promise. Les versions binaires officielles sont dans [homebrew-sema](https://github.com/antoineberjoan/homebrew-sema/releases), avec leur empreinte SHA-256.

L’alpha actuelle utilise une signature ad hoc et n’est pas notarisée par Apple. Une empreinte permet de comparer un téléchargement à l’artefact publié ; elle ne remplace pas une notarisation ni un audit de sécurité. La documentation d’installation ne demande pas de désactiver Gatekeeper ni de retirer la quarantaine.
