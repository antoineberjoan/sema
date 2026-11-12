// Les workflows d'un dépôt (fonder § 6, « Le filet ») : trois règles de budget que le texte du workflow
// permet de vérifier sans ambiguïté. Aucune dépendance. `politique.mjs --verifier` l'appelle.
//
//   1. chaque job porte `timeout-minutes` : un job bloqué coûte jusqu'à six heures de minutes ;
//   2. une CI lancée par `push` ou `pull_request` annule l'exécution précédente (`concurrency` avec
//      `cancel-in-progress`) : seul le dernier envoi compte ;
//   3. aucun job sur macOS hébergé (compté ×10) : le macOS passe par le runner auto-hébergé du Mac.
//
// Ce que le texte ne dit pas (un job lourd qui saute les brouillons, un seul contrôle exigé) reste écrit
// dans `fonder` § 6, sans contrôle : une règle qu'on ne sait pas vérifier ne se fait pas passer pour un cliquet.

/** Le texte d'un workflow sans ses commentaires. */
const lignesSansCommentaire = (texte) => texte.split("\n").map((ligne) => ligne.replace(/(^|\s)#.*$/, "").replace(/\s+$/, ""));

function lireDeclencheurs(lignes) {
  const debut = lignes.findIndex((ligne) => /^("on"|'on'|on):/.test(ligne));
  if (debut < 0) return new Set();
  const reste = lignes[debut].replace(/^("on"|'on'|on):/, "").trim();
  if (reste.startsWith("[")) return new Set(reste.slice(1, -1).split(",").map((nom) => nom.trim()).filter(Boolean));
  if (reste.startsWith("{")) return new Set([...reste.matchAll(/([\w-]+)\s*:/g)].map((paire) => paire[1]));
  if (reste !== "") return new Set([reste]);
  const noms = new Set();
  let retrait = null;
  for (const ligne of lignes.slice(debut + 1)) {
    if (ligne.trim() === "") continue;
    const courant = ligne.length - ligne.trimStart().length;
    if (courant === 0) break;
    retrait ??= courant;
    if (courant !== retrait) continue;
    const cle = ligne.match(/^\s+([\w-]+):/) ?? ligne.match(/^\s+-\s*([\w-]+)/);
    if (cle) noms.add(cle[1]);
  }
  return noms;
}

function lireJobs(lignes) {
  const debut = lignes.findIndex((ligne) => /^jobs:\s*$/.test(ligne));
  if (debut < 0) return [];
  const jobs = [];
  let courant = null;
  for (const ligne of lignes.slice(debut + 1)) {
    if (ligne.trim() === "") continue;
    if (!/^\s/.test(ligne)) break;
    const identifiant = ligne.match(/^ {2}([\w-]+):\s*$/);
    if (identifiant) {
      courant = { id: identifiant[1], lignes: [] };
      jobs.push(courant);
    } else if (courant) {
      courant.lignes.push(ligne);
    }
  }
  return jobs.map(({ id, lignes: corps }) => {
    const proprietes = corps.filter((ligne) => /^ {4}\S/.test(ligne));
    const valeur = (cle) => proprietes.find((ligne) => ligne.trim().startsWith(`${cle}:`))?.trim().slice(cle.length + 1).trim();
    // `runs-on` peut s'écrire sur plusieurs lignes (liste) : on prend la ligne et ses éléments.
    const iRunsOn = corps.findIndex((ligne) => /^ {4}runs-on:/.test(ligne));
    let runsOn = iRunsOn < 0 ? "" : corps[iRunsOn].trim().slice("runs-on:".length).trim();
    if (iRunsOn >= 0 && runsOn === "") {
      for (const suite of corps.slice(iRunsOn + 1)) {
        if (/^ {4}\S/.test(suite)) break;
        runsOn += ` ${suite.trim()}`;
      }
    }
    return { id, timeout: valeur("timeout-minutes") !== undefined, reutilise: valeur("uses") !== undefined, runsOn };
  });
}

/** Lit un workflow : ses déclencheurs, son annulation des exécutions précédentes et ses jobs. */
export function lireWorkflow(texte) {
  const lignes = lignesSansCommentaire(texte);
  return {
    declencheurs: lireDeclencheurs(lignes),
    annule: lignes.some((ligne) => /^concurrency:/.test(ligne)) && lignes.some((ligne) => /cancel-in-progress:\s*(true|\$\{\{)/.test(ligne)),
    jobs: lireJobs(lignes),
  };
}

/** Les infractions de budget d'un ensemble de workflows : [{ fichier, message }], dans l'ordre des fichiers. */
export function verifierWorkflows(fichiers) {
  const infractions = [];
  for (const { nom, texte } of [...fichiers].sort((a, b) => a.nom.localeCompare(b.nom))) {
    const workflow = lireWorkflow(texte);
    const dit = (message) => infractions.push({ fichier: nom, message });
    if ([...workflow.declencheurs].some((declencheur) => declencheur === "push" || declencheur === "pull_request") && !workflow.annule) {
      dit("sans `concurrency` avec `cancel-in-progress: true`. Ajouter `concurrency: { group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}, cancel-in-progress: true }` : un nouvel envoi annule l'exécution en cours au lieu de l'ajouter à la file.");
    }
    for (const job of workflow.jobs) {
      if (!job.timeout && !job.reutilise) {
        dit(`job « ${job.id} » sans \`timeout-minutes\`. Un job bloqué tourne jusqu'à six heures : ajouter \`timeout-minutes: 30\` (ou la durée réelle, arrondie).`);
      }
      if (/macos/i.test(job.runsOn) && !/self-hosted/i.test(job.runsOn)) {
        dit(`job « ${job.id} » sur macOS hébergé (\`${job.runsOn}\`) : chaque minute compte pour dix. Le faire tourner sur le runner auto-hébergé du Mac : \`runs-on: [self-hosted, macOS]\` (dépôt privé seulement).`);
      }
    }
  }
  return infractions;
}
