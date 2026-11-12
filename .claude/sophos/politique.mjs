#!/usr/bin/env node
// La politique d'un dépôt (construire, « Un chantier, toujours le même chemin ») : le niveau de risque d'une PR
// (vert, orange, rouge) se calcule à partir des fichiers qu'elle touche, d'après la section
// `politique` de `projet.yml` lue sur la branche de base. Aucune dépendance.
//
//   node ../sophos/outils/politique.mjs --classer [REF] [--base BRANCHE]   niveau de REF (HEAD) contre origin/BRANCHE (main)
//   node ../sophos/outils/politique.mjs --autoriser PR                    la PR peut-elle être fusionnée ? (gh) ; imprime la ligne « Niveau: … » du commit de fusion
//   node ../sophos/outils/politique.mjs --github                           prépare le dépôt : étiquette accord, fusion par commit de fusion seulement (gh)
//   node ../sophos/outils/politique.mjs --controler [--base B]            lance le lanceur du projet, puis gitleaks sur les commits à envoyer
//   node ../sophos/outils/politique.mjs --verifier                         la section politique est valide, aucun motif mort, les workflows respectent le budget
//
// Le niveau le plus sévère gagne : un chemin prend le plus haut niveau parmi le socle ci-dessous et
// ses motifs ; un chemin sans motif prend `defaut`. Le niveau de la PR est le plus haut de ses chemins.

import { execFileSync, spawnSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { ErreurFiche, FICHE, NIVEAUX, lireFiche, verifierFiche, verifierPolitique } from "./fiche.mjs";
import { verifierWorkflows } from "./workflows.mjs";

export class ErreurPolitique extends Error {}

function echouer(message) {
  throw new ErreurPolitique(message);
}

// Le socle : ce qui change le comportement de la machine ou des agents ne descend jamais sous ce niveau,
// quoi que dise la fiche d'un dépôt. Ce n'est pas configurable.
const SOCLE = [
  { glob: ".github/workflows/**", niveau: "rouge" },
  { glob: ".claude/**", niveau: "orange" },
  { glob: ".githooks/**", niveau: "orange" },
  { glob: "AGENTS.md", niveau: "orange" },
  { glob: "**/AGENTS.md", niveau: "orange" },
  { glob: "CLAUDE.md", niveau: "orange" },
  { glob: "**/CLAUDE.md", niveau: "orange" },
];

// ---------- Noyau pur : aucune lecture de fichier, aucun appel à git ----------

/** Un motif devient une expression régulière sur un chemin relatif à la racine. */
export function compilerGlob(glob) {
  const segments = glob.split("/");
  let source = "";
  segments.forEach((segment, index) => {
    const dernier = index === segments.length - 1;
    if (segment === "**") {
      source += dernier ? ".*" : "(?:[^/]+/)*";
      return;
    }
    const corps = segment.replace(/[.+^${}()|\\]/g, "\\$&").replace(/\*/g, "[^/]*").replace(/\?/g, "[^/]");
    source += dernier ? corps : `${corps}/`;
  });
  return new RegExp(`^${source}$`);
}

/** La section politique d'une fiche déjà lue, sous une forme où rien n'est facultatif. */
export function lirePolitique(fiche) {
  if (fiche.politique === undefined) echouer(`${FICHE} n'a pas de section « politique ». Voir outils/README.md.`);
  const { politique } = fiche;
  return {
    defaut: politique.defaut,
    listes: Object.fromEntries(NIVEAUX.map((niveau) => [niveau, politique[niveau] ?? []])),
    gardes: politique.gardes ?? [],
    controle: politique.controle,
    cliquet: Object.fromEntries(Object.entries(politique.cliquet ?? {}).map(([chemin, entree]) => [chemin, { niveau: entree.niveau, fusion: entree.fusion }])),
  };
}

const rang = (niveau) => NIVEAUX.indexOf(niveau);

/**
 * Le niveau d'un changement. `changements` : [{ statut, chemin }] (un renommage compte pour une suppression
 * et un ajout, donc les deux chemins sont classés). `relachee` : la politique de la PR est plus lâche que
 * celle de la base, ce qui remonte `projet.yml` au moins en orange.
 */
export function classer(politique, changements, { relachee = false } = {}) {
  if (changements.length === 0) echouer("aucun fichier modifié : rien à classer.");
  const regles = [
    ...SOCLE.map(({ glob, niveau }) => ({ glob, niveau, origine: `socle ${glob}` })),
    { glob: politique.controle.replace(/^\.\//, ""), niveau: "orange", origine: `socle ${politique.controle} (le lanceur du projet)` },
    ...(relachee ? [{ glob: FICHE, niveau: "orange", origine: `socle ${FICHE} (la politique se relâche)` }] : []),
    ...NIVEAUX.flatMap((niveau) => politique.listes[niveau].map((glob) => ({ glob, niveau, origine: `politique.${niveau} ${glob}` }))),
    ...Object.entries(politique.cliquet).map(([chemin, entree]) => ({ glob: chemin, niveau: entree.niveau, origine: `cliquet ${entree.fusion} (une fusion verte a été annulée)` })),
  ].map((regle) => ({ ...regle, motif: compilerGlob(regle.glob) }));

  const raisons = [...new Set(changements.map((changement) => changement.chemin))].sort().map((chemin) => {
    const touchees = regles.filter((regle) => regle.motif.test(chemin));
    if (touchees.length === 0) return { chemin, niveau: politique.defaut, regle: "defaut" };
    const pire = touchees.reduce((a, b) => (rang(b.niveau) > rang(a.niveau) ? b : a));
    return { chemin, niveau: pire.niveau, regle: pire.origine };
  });
  const niveau = raisons.reduce((haut, raison) => (rang(raison.niveau) > rang(haut) ? raison.niveau : haut), NIVEAUX[0]);
  return { niveau, raisons };
}

/**
 * Compare la politique de la base à celle de la PR : `identique`, `resserree` (jamais plus lâche : le niveau
 * par défaut ne baisse pas, les listes orange et rouge et les gardes ne perdent rien, la liste verte ne gagne rien)
 * ou `relachee`. Toute autre différence est un relâchement.
 */
export function comparerPolitiques(base, tete) {
  const texte = (politique) => JSON.stringify(politique);
  if (texte(base) === texte(tete)) return "identique";
  const contient = (grande, petite) => petite.every((element) => grande.includes(element));
  const resserree =
    rang(tete.defaut) >= rang(base.defaut) &&
    contient(tete.listes.orange, base.listes.orange) &&
    contient(tete.listes.rouge, base.listes.rouge) &&
    contient(base.listes.vert, tete.listes.vert) &&
    contient(tete.gardes, base.gardes) &&
    tete.controle === base.controle &&
    Object.entries(base.cliquet).every(([chemin, entree]) => tete.cliquet[chemin] && rang(tete.cliquet[chemin].niveau) >= rang(entree.niveau));
  return resserree ? "resserree" : "relachee";
}

/** La ligne qui trace le niveau dans le commit de fusion. */
export const ligneNiveau = (niveau) => `Niveau: ${niveau}`;

const RELECTURE = /^## Relecture croisée[ \t]*\n+[ \t]*(https:\/\/github\.com\/[\w.-]+\/[\w.-]+\/(?:issues|pull)\/\d+#issuecomment-\d+)/m;

/**
 * Ce que la frise d'une PR dit de l'étiquette `accord` : `parUnHumain` (posée par une personne, pas par une
 * application) et `apresDernierCommit` (aucun envoi depuis). `null` quand la frise ne permet pas de savoir.
 * `evenements` : [{ evenement, date, etiquette, application }], dans n'importe quel ordre.
 */
export function lireAccord(evenements) {
  const poses = evenements.filter((e) => e.evenement === "labeled" && e.etiquette === "accord").sort((a, b) => a.date.localeCompare(b.date));
  if (poses.length === 0) return { parUnHumain: null, apresDernierCommit: null };
  const derniere = poses.at(-1);
  const envois = evenements.filter((e) => e.evenement === "committed" || e.evenement === "head_ref_force_pushed").map((e) => e.date);
  return {
    parUnHumain: !derniere.application,
    apresDernierCommit: envois.length === 0 ? null : envois.every((date) => date < derniere.date),
  };
}

const PAS_VERIFIE = /^## Pas vérifié[ \t]*\n+[ \t]*[^\s#]/m;
const ISSUE_FERMEE = /^Closes #\d+[ \t]*$/m;

/**
 * Ce qui manque au texte d'une PR pour son niveau (construire, « Selon le risque »), ou null. Vert : une phrase.
 * Orange : de plus la section `## Pas vérifié`, remplie. Rouge : de plus l'issue fermée par `Closes #N`.
 * Le seul endroit où le texte d'une PR est contrôlé, pour le Mac comme pour une session cloud.
 */
export function texteManquant(niveau, corps) {
  const texte = (corps ?? "").replace(/<!--[\s\S]*?-->/g, "");
  if (texte.trim() === "") return "la description est vide : dire en une phrase ce qui change.";
  if (niveau === "vert") return null;
  if (!PAS_VERIFIE.test(texte)) return `niveau ${niveau} : la description n'a pas de section « ## Pas vérifié » remplie. Elle dit ce qu'aucun test ni aucune lecture n'a contrôlé ; « Rien. » est une réponse.`;
  if (niveau === "rouge" && !ISSUE_FERMEE.test(texte)) return "niveau rouge : la description ne ferme aucune issue. Ajouter une ligne « Closes #N » : un chantier rouge part d'une issue.";
  return null;
}

/**
 * La décision de fusion, d'après le niveau (construire, « Selon le risque »). `faits` : { niveau, methode, labels, accord, corps, gardes }.
 * Toujours un commit de fusion, et le texte que le niveau demande. Vert : fusion libre. Orange : l'étiquette `accord`,
 * posée par une personne, avant tout nouvel envoi. Rouge : de plus la section `## Relecture croisée` avec le lien de
 * l'arbitrage, et soit GitHub garde lui-même l'accord (`gardes` contient `niveau`), soit la frise prouve l'accord.
 */
export function decider({ niveau, methode = "merge", labels, accord, corps, gardes }) {
  const refus = (raison) => ({ permis: false, raison });
  if (methode !== "merge") return refus("une PR se fusionne par un commit de fusion (`--merge`), pas par « squash » ni « rebase » : le commit porte son niveau et s'annule d'un seul `git revert -m 1`.");
  const manque = texteManquant(niveau, corps);
  if (manque !== null) return refus(manque);
  if (niveau === "vert") return { permis: true, raison: "niveau vert : fusion libre." };
  if (!labels.includes("accord")) return refus(`niveau ${niveau} : il manque l'étiquette « accord », que seul Antoine pose sur la PR.`);
  if (accord.parUnHumain === false) return refus("l'étiquette « accord » a été posée par une application, pas par une personne : Antoine la pose lui-même.");
  if (accord.apresDernierCommit === false) return refus("un envoi a suivi l'étiquette « accord » : l'accord porte sur le code relu. Antoine la repose après avoir vu le dernier envoi.");
  if (niveau === "orange") return { permis: true, raison: "niveau orange : accord présent." };
  if (!RELECTURE.test(corps ?? "")) return refus("niveau rouge : la description n'a pas de section `## Relecture croisée` suivie du lien du commentaire d'arbitrage (voir `relire`).");
  if (!gardes.includes("niveau") && !(accord.parUnHumain === true && accord.apresDernierCommit === true)) {
    return refus("niveau rouge : la frise de la PR ne prouve pas l'accord (qui l'a posé, et quand). Fusionner depuis le Mac avec `gh`, ou déclarer `gardes: [niveau]` pour que GitHub le garde.");
  }
  return { permis: true, raison: "niveau rouge : relecture croisée et accord présents." };
}

// ---------- Le cliquet : l'autonomie se perd vite et se regagne par Antoine ----------

/** Les identifiants des commits qu'un message annule (« This reverts commit … »). */
export const lireReverts = (message) => [...message.matchAll(/This reverts commit ([0-9a-f]{7,40})/g)].map((trouve) => trouve[1]);

/**
 * Les entrées du cliquet qu'une fusion verte annulée impose : chaque fichier qu'elle touchait monte d'un niveau (vert →
 * orange, orange → rouge). Les entrées déjà posées pour cette fusion ne comptent pas : relancer ne monte pas deux fois.
 */
export function entreesCliquet(politique, fichiers, fusion) {
  const sans = { ...politique, cliquet: Object.fromEntries(Object.entries(politique.cliquet).filter(([, entree]) => entree.fusion !== fusion.slice(0, entree.fusion.length) && !fusion.startsWith(entree.fusion))) };
  const entrees = {};
  for (const chemin of [...new Set(fichiers)].sort()) {
    const actuel = classer(sans, [{ statut: "M", chemin }]).niveau;
    if (actuel !== "rouge") entrees[chemin] = { niveau: NIVEAUX[rang(actuel) + 1], fusion: fusion.slice(0, 12) };
  }
  return entrees;
}

/** Ce qui manque au cliquet d'une PR qui annule des fusions vertes : [{ fusion, chemins }]. */
export function manquantsCliquet(politique, fusionsVertes) {
  return fusionsVertes
    .map(({ fusion, fichiers }) => ({
      fusion,
      chemins: Object.entries(entreesCliquet(politique, fichiers, fusion))
        .filter(([chemin, voulue]) => !(politique.cliquet[chemin] && rang(politique.cliquet[chemin].niveau) >= rang(voulue.niveau)))
        .map(([chemin]) => chemin),
    }))
    .filter(({ chemins }) => chemins.length > 0);
}

/** Réécrit le seul bloc `cliquet:` de la section politique d'une fiche : trié, un fichier par ligne, idempotent. */
export function resserrerTexte(texte, cliquet) {
  const lignes = texte.split("\n");
  const debut = lignes.findIndex((ligne) => /^politique:\s*$/.test(ligne));
  if (debut < 0) echouer(`${FICHE} n'a pas de section « politique ».`);
  let fin = lignes.length;
  for (let i = debut + 1; i < lignes.length; i += 1) {
    if (lignes[i].trim() !== "" && !/^\s/.test(lignes[i]) && !lignes[i].startsWith("#")) {
      fin = i;
      break;
    }
  }
  let bloc = lignes.slice(debut + 1, fin);
  const vides = bloc.length - bloc.findLastIndex((ligne) => ligne.trim() !== "") - 1;
  const iCliquet = bloc.findIndex((ligne) => /^ {2}cliquet:\s*$/.test(ligne));
  if (iCliquet >= 0) {
    let j = iCliquet + 1;
    while (j < bloc.length && (bloc[j].trim() === "" || /^ {3,}\S/.test(bloc[j]))) j += 1;
    bloc = [...bloc.slice(0, iCliquet), ...bloc.slice(j)];
  }
  while (bloc.length > 0 && bloc.at(-1).trim() === "") bloc.pop();
  const entrees = Object.entries(cliquet).sort(([a], [b]) => a.localeCompare(b));
  if (entrees.length > 0) bloc.push("  cliquet:", ...entrees.map(([chemin, e]) => `    ${chemin}: { niveau: ${e.niveau}, fusion: ${e.fusion} }`));
  const avant = lignes.slice(0, debut + 1);
  const apres = lignes.slice(fin);
  return [...avant, ...bloc, ...Array(vides).fill(""), ...apres].join("\n");
}

/** Ce que `--github` règle : l'étiquette que la décision de fusion lit, et le mode de fusion du dépôt. */
export const ETIQUETTES = [{ nom: "accord", couleur: "0E8A16", description: "Accord d'Antoine : lui seul pose cette étiquette" }];
export const REGLAGES_DEPOT = { allow_merge_commit: true, allow_squash_merge: false, allow_rebase_merge: false, delete_branch_on_merge: true, allow_auto_merge: false };

// ---------- Coquille : git et fichiers ----------

function git(...arguments_) {
  try {
    return execFileSync("git", arguments_, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], maxBuffer: 64 * 1024 * 1024 });
  } catch (erreur) {
    const detail = String(erreur.stderr ?? erreur.message).trim();
    echouer(`git ${arguments_.join(" ")} : ${detail}\nSi la branche de base est introuvable : git fetch origin <base> (et git fetch --deepen=200 si le dépôt est un clone court).`);
  }
}

/** Les chemins changés entre la base et REF, sans détection de renommage. */
export function lireChangements(base, ref) {
  const jetons = git("diff", "-z", "--name-status", "--no-renames", `origin/${base}...${ref}`).split("\0").filter((jeton) => jeton !== "");
  const changements = [];
  for (let i = 0; i + 1 < jetons.length; i += 2) changements.push({ statut: jetons[i], chemin: jetons[i + 1] });
  return changements;
}

function lireFicheA(ref) {
  return lireFiche(git("show", `${ref}:${FICHE}`));
}

export function politiqueA(ref, nom) {
  const fiche = (() => {
    try {
      return lireFicheA(ref);
    } catch (erreur) {
      if (erreur instanceof ErreurFiche) throw erreur;
      throw new ErreurPolitique(`${FICHE} introuvable sur ${nom} : ${erreur.message}`);
    }
  })();
  if (fiche.politique === undefined) {
    echouer(`${FICHE} sur ${nom} n'a pas de section « politique ». Première PR de la politique dans ce dépôt : à fusionner à la main, puis la section existe sur la base.`);
  }
  verifierPolitique(fiche.politique);
  return lirePolitique(fiche);
}

/** Une fusion de PR dont le commit porte « Niveau: vert » : ses fichiers, ou une erreur qui dit pourquoi ce n'en est pas une. */
function fusionVerte(sha) {
  const fusion = git("rev-parse", "--verify", `${sha}^{commit}`).trim();
  if (git("rev-list", "--parents", "-n", "1", fusion).trim().split(" ").length < 3) echouer(`${sha} n'est pas un commit de fusion : le cliquet ne suit que les fusions de PR.`);
  if (!git("show", "-s", "--format=%B", fusion).split("\n").includes(ligneNiveau("vert"))) echouer(`${sha} ne porte pas « ${ligneNiveau("vert")} » : seule l'annulation d'une fusion verte fait monter un fichier.`);
  return { fusion, fichiers: git("diff", "--name-only", "-z", `${fusion}^1`, fusion).split("\0").filter(Boolean) };
}

/** Les fusions vertes que les commits de `ref` annulent (« This reverts commit … »). */
function fusionsVertesAnnulees(ref, base) {
  const messages = git("log", "--format=%B%x01", `origin/${base}..${ref}`).split("\x01");
  const annulees = [...new Set(messages.flatMap(lireReverts))];
  return annulees.flatMap((sha) => {
    try {
      return [fusionVerte(sha)];
    } catch {
      return [];
    }
  });
}

export function classerRef(ref, base) {
  const politiqueBase = politiqueA(`origin/${base}`, `origin/${base}`);
  const changements = lireChangements(base, ref);
  let relachee = false;
  if (changements.some((changement) => changement.chemin === FICHE)) {
    try {
      relachee = comparerPolitiques(politiqueBase, politiqueA(ref, ref)) === "relachee";
    } catch {
      relachee = true;
    }
  }
  let manquants = [];
  try {
    manquants = manquantsCliquet(politiqueA(ref, ref), fusionsVertesAnnulees(ref, base));
  } catch {
    manquants = [];
  }
  return { ...classer(politiqueBase, changements, { relachee }), manquants };
}

/** `--resserrer SHA` : après l'annulation d'une fusion verte, ses fichiers montent d'un niveau dans le cliquet de la fiche. */
function resserrer(racine, sha) {
  const { fusion, fichiers } = fusionVerte(sha);
  if (spawnSync("git", ["merge-base", "--is-ancestor", fusion, "HEAD"], { cwd: racine }).status !== 0) echouer(`${sha} n'est pas dans l'historique de HEAD : lancer depuis la branche principale à jour.`);
  const chemin = join(racine, FICHE);
  const texte = readFileSync(chemin, "utf8");
  const politique = lirePolitique(lireFiche(texte));
  const suivis = new Set(git("ls-files", "-z").split("\0").filter(Boolean));
  const entrees = entreesCliquet(politique, fichiers.filter((fichier) => suivis.has(fichier)), fusion);
  const sans = Object.fromEntries(Object.entries(politique.cliquet).filter(([, entree]) => !fusion.startsWith(entree.fusion)));
  const nouveau = resserrerTexte(texte, { ...sans, ...entrees });
  verifierPolitique(lireFiche(nouveau).politique);
  if (nouveau !== texte) writeFileSync(chemin, nouveau);
  const liste = Object.entries(entrees);
  return liste.length === 0 ? `Cliquet déjà à jour pour ${fusion.slice(0, 12)}.` : `Cliquet : ${liste.map(([c, e]) => `${c} → ${e.niveau}`).join(", ")} (fusion ${fusion.slice(0, 12)} annulée).`;
}

function gh(...arguments_) {
  try {
    return execFileSync("gh", arguments_, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], maxBuffer: 64 * 1024 * 1024 });
  } catch (erreur) {
    echouer(`gh ${arguments_.join(" ")} : ${String(erreur.stderr ?? erreur.message).trim()}`);
  }
}

/** La PR et sa frise, lues par `gh`, rassemblées en faits pour `decider`. */
function lireFaits(numero) {
  const pr = JSON.parse(gh("pr", "view", String(numero), "--json", "state,headRefName,baseRefName,labels,body"));
  if (pr.state !== "OPEN") echouer(`la PR #${numero} n'est pas ouverte (${pr.state}).`);
  const lignes = gh("api", `repos/{owner}/{repo}/issues/${numero}/timeline`, "--paginate", "--jq",
    ".[] | {evenement: .event, date: (.created_at // .committer.date), etiquette: .label.name, application: .performed_via_github_app.slug}")
    .split("\n").filter((ligne) => ligne.trim() !== "");
  const evenements = lignes.map((ligne) => JSON.parse(ligne)).filter((e) => e.date);
  git("fetch", "--quiet", "origin", pr.baseRefName, pr.headRefName);
  return { pr, evenements };
}

/** Le message d'une PR qui annule une fusion verte sans que le cliquet monte. */
export const messageCliquet = (manquants) => `Cette PR annule la fusion verte ${manquants[0].fusion.slice(0, 12)} : ${manquants[0].chemins.join(", ")} doivent monter d'un niveau. Lancer node <sophos>/outils/politique.mjs --resserrer ${manquants[0].fusion.slice(0, 12)}, committer projet.yml dans cette PR.`;

function autoriser(numero) {
  const { pr, evenements } = lireFaits(numero);
  const base = politiqueA(`origin/${pr.baseRefName}`, `origin/${pr.baseRefName}`);
  const { niveau, raisons, manquants } = classerRef(`origin/${pr.headRefName}`, pr.baseRefName);
  if (manquants.length > 0) echouer(`fusion refusée. ${messageCliquet(manquants)}`);
  const decision = decider({ niveau, methode: "merge", labels: pr.labels.map((etiquette) => etiquette.name), accord: lireAccord(evenements), corps: pr.body, gardes: base.gardes });
  console.error(`niveau ${niveau} : ${raisons.map((raison) => `${raison.chemin} (${raison.regle})`).slice(0, 5).join(", ")}${raisons.length > 5 ? ", …" : ""}`);
  if (!decision.permis) echouer(`fusion refusée. ${decision.raison}`);
  console.error(`fusion autorisée : ${decision.raison}`);
  console.log(ligneNiveau(niveau));
}

function preparerGithub(racine) {
  const fiche = verifierFiche(lireFiche(readFileSync(join(racine, FICHE), "utf8")), racine);
  for (const etiquette of ETIQUETTES) {
    gh("label", "create", etiquette.nom, "--color", etiquette.couleur, "--description", etiquette.description, "--force");
    console.log(`étiquette ${etiquette.nom} : prête.`);
  }
  gh("api", "-X", "PATCH", `repos/${fiche.depot}`, ...Object.entries(REGLAGES_DEPOT).flatMap(([cle, valeur]) => ["-F", `${cle}=${valeur}`]));
  console.log(`${fiche.depot} : fusion par commit de fusion seulement, branches supprimées après fusion, fusion automatique GitHub interdite.`);
}

/** Les dernières lignes d'une sortie, pour un message de refus qui tient à l'écran. */
const fin = (texte, lignes = 25) => texte.trim().split("\n").slice(-lignes).join("\n");

/**
 * Les contrôles locaux avant d'envoyer du code : le lanceur unique du projet (`politique.controle`), puis gitleaks sur les
 * commits que le push enverrait (`origin/<base>..HEAD`). Rend le texte du refus, ou null quand tout passe. Un gitleaks
 * absent est un échec, jamais un contrôle sauté en silence : un secret envoyé sur GitHub y reste dans l'historique.
 */
export function controler(racine, base = "main") {
  const { controle } = lirePolitique(lireFiche(readFileSync(join(racine, FICHE), "utf8")));
  const lanceur = spawnSync("sh", ["-c", controle], { cwd: racine, encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
  if (lanceur.status !== 0) return `${controle} a échoué (code ${lanceur.status}). Corriger, puis renvoyer.\n${fin(`${lanceur.stdout}\n${lanceur.stderr}`)}`;
  const secrets = spawnSync("gitleaks", ["git", "--redact", "--no-banner", "--log-opts", `origin/${base}..HEAD`, racine], { encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
  if (secrets.error?.code === "ENOENT") return "gitleaks est absent : sans lui, un secret pourrait partir sur GitHub. Sur le Mac : brew install gitleaks. Dans une session cloud : l'ajouter au script d'installation de l'environnement.";
  if (secrets.status !== 0) return `gitleaks a trouvé un secret dans les commits à envoyer (origin/${base}..HEAD). Le retirer de l'historique de la branche (pas seulement du dernier commit), puis renvoyer.\n${fin(`${secrets.stdout}\n${secrets.stderr}`)}`;
  return null;
}

function verifier(racine) {
  const chemin = join(racine, FICHE);
  if (!existsSync(chemin)) echouer(`${FICHE} manque à la racine de ${racine}.`);
  const fiche = verifierFiche(lireFiche(readFileSync(chemin, "utf8")), racine);
  const politique = lirePolitique(fiche);
  const suivis = git("ls-files", "-z").split("\0").filter((fichier) => fichier !== "");
  for (const niveau of NIVEAUX) {
    for (const glob of politique.listes[niveau]) {
      const motif = compilerGlob(glob);
      if (!suivis.some((fichier) => motif.test(fichier))) {
        echouer(`politique.${niveau} : le motif « ${glob} » ne correspond à aucun fichier suivi. Une règle morte se retire, ou se corrige si le dossier a bougé.`);
      }
    }
  }
  const dossier = join(racine, ".github", "workflows");
  const workflows = existsSync(dossier)
    ? readdirSync(dossier).filter((nom) => /\.ya?ml$/.test(nom)).map((nom) => ({ nom: `.github/workflows/${nom}`, texte: readFileSync(join(dossier, nom), "utf8") }))
    : [];
  const infractions = verifierWorkflows(workflows);
  if (infractions.length > 0) {
    echouer(`Budget des workflows (fonder § 6.3) :\n${infractions.map(({ fichier, message }) => `- ${fichier} : ${message}`).join("\n")}`);
  }
}

// ---------- Programme ----------

function lancer(arguments_) {
  const options = new Map();
  const positionnels = [];
  for (let i = 0; i < arguments_.length; i += 1) {
    if (arguments_[i] === "--base") {
      options.set("--base", arguments_[i + 1]);
      i += 1;
    } else if (arguments_[i].startsWith("--")) {
      options.set(arguments_[i], true);
    } else {
      positionnels.push(arguments_[i]);
    }
  }
  const connues = ["--classer", "--verifier", "--autoriser", "--github", "--controler", "--resserrer", "--base"];
  const inconnues = [...options.keys()].filter((option) => !connues.includes(option));
  const commandes = ["--classer", "--verifier", "--autoriser", "--github", "--controler", "--resserrer"].filter((commande) => options.has(commande));
  const attendus = options.has("--classer") || options.has("--autoriser") || options.has("--resserrer") ? 1 : 0;
  const numeroValide = (!options.has("--autoriser") || /^\d+$/.test(positionnels[0] ?? "")) && (!options.has("--resserrer") || /^[0-9a-f]{7,40}$/.test(positionnels[0] ?? ""));
  if (inconnues.length > 0 || commandes.length !== 1 || positionnels.length > attendus || !numeroValide || (options.has("--base") && !options.get("--base"))) {
    console.error("Usage : node politique.mjs --classer [REF] [--base BRANCHE] | --autoriser PR | --resserrer SHA | --github | --controler [--base BRANCHE] | --verifier");
    return 2;
  }
  if (options.has("--autoriser")) {
    autoriser(Number(positionnels[0]));
    return 0;
  }
  if (options.has("--github")) {
    preparerGithub(process.cwd());
    return 0;
  }
  if (options.has("--resserrer")) {
    console.log(resserrer(process.cwd(), positionnels[0]));
    return 0;
  }
  if (options.has("--controler")) {
    const refus = controler(process.cwd(), options.get("--base") ?? "main");
    if (refus !== null) {
      console.error(refus);
      return 1;
    }
    console.log("Contrôles passés.");
    return 0;
  }
  if (options.has("--verifier")) {
    verifier(process.cwd());
    console.log("Politique à jour.");
    return 0;
  }
  const base = options.get("--base") ?? "main";
  const { niveau, raisons, manquants } = classerRef(positionnels[0] ?? "HEAD", base);
  console.log(`niveau: ${niveau}`);
  for (const raison of raisons) console.log(`  ${raison.niveau.padEnd(6)} ${raison.chemin}  (${raison.regle})`);
  if (manquants.length > 0) console.log(`cliquet manquant : ${messageCliquet(manquants)}`);
  return 0;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    process.exitCode = lancer(process.argv.slice(2));
  } catch (erreur) {
    if (!(erreur instanceof ErreurPolitique || erreur instanceof ErreurFiche)) throw erreur;
    console.error(erreur.message);
    process.exitCode = 1;
  }
}
