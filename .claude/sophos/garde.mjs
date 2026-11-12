#!/usr/bin/env node
// La garde des agents (construire, « Les étapes », 4) : ce que Claude Code a le droit de faire dans un dépôt, déduit de
// sa politique. Elle fabrique `.claude/settings.json` (permissions étroites et hooks) et sert les deux hooks :
// un relevé de ce que GitHub répond sur une PR, et le contrôle avant une fusion ou avant de poser `accord`.
// Aucune dépendance. Les refus sont des codes de sortie 2 avec la raison sur stderr ; une panne du hook ne
// bloque jamais (code 1) : seul un refus voulu arrête l'agent.
//
//   node ../sophos/outils/garde.mjs             écrit .claude/settings.json (et, hors de Sophos, les copies .claude/sophos/)
//   node ../sophos/outils/garde.mjs --verifier  n'écrit rien ; sortie 1 si le réglage ou les copies ont dérivé
//   node ../sophos/outils/garde.mjs --noter     hook PostToolUse : relève la PR et ses étiquettes (entrée standard)
//   node ../sophos/outils/garde.mjs --garder    hook PreToolUse : refuse une fusion non autorisée ou un « accord » posé par l'agent
//   node ../sophos/outils/garde.mjs --pousser   hook Git pre-push : les contrôles du projet avant tout envoi, pour tout agent et toute personne
//
// Le hook Git (`.githooks/pre-push`) vaut pour tous : c'est Git qui le lance. Il ne coûte rien à GitHub. Il s'active
// par copie du dépôt (`git config core.hooksPath .githooks`) ; la garde le fait, sauf si le dépôt a déjà ses hooks.

import { execFileSync } from "node:child_process";
import { chmodSync, existsSync, mkdirSync, readFileSync, readdirSync, realpathSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { ErreurFiche, FICHE, lireFiche } from "./fiche.mjs";
import { ErreurPolitique, classerRef, controler, decider, ligneNiveau, messageCliquet, politiqueA } from "./politique.mjs";

const REGLAGES = ".claude/settings.json";
const COPIES = ".claude/sophos";
export const OUTILS_COPIES = ["fiche.mjs", "workflows.mjs", "politique.mjs", "garde.mjs"];
const OUTILS = dirname(fileURLToPath(import.meta.url));
export const HOOKS_GIT = ".githooks";
const PRE_PUSH = `${HOOKS_GIT}/pre-push`;

// ---------- Noyau pur ----------

/** La réponse d'un outil MCP sous toutes ses formes : chaîne JSON, objet, liste de blocs { type: "text", text }. */
export function lireReponse(reponse) {
  if (reponse == null) return null;
  if (typeof reponse === "string") {
    try {
      return JSON.parse(reponse);
    } catch {
      return null;
    }
  }
  if (Array.isArray(reponse)) {
    const blocs = reponse.filter((bloc) => bloc && typeof bloc === "object" && typeof bloc.text === "string");
    if (blocs.length > 0 && blocs.length === reponse.length) return lireReponse(blocs.map((bloc) => bloc.text).join(""));
    return reponse;
  }
  if (typeof reponse === "object" && Array.isArray(reponse.content)) return lireReponse(reponse.content);
  return reponse;
}

/** Les faits d'une PR relevés par `pull_request_read` (méthode get), ou null si la réponse n'a pas la forme attendue. */
export function faitsDePr(reponse) {
  const pr = lireReponse(reponse);
  if (!pr || typeof pr !== "object" || typeof pr.number !== "number" || !pr.head?.sha || !pr.head?.ref || !pr.base?.ref) return null;
  return { numero: pr.number, base: pr.base.ref, branche: pr.head.ref, tete: pr.head.sha, corps: pr.body ?? "", etat: pr.state ?? null };
}

/** Les noms d'étiquettes relevés par `issue_read` (méthode get_labels), ou null. */
export function etiquettesDe(reponse) {
  const lu = lireReponse(reponse);
  const liste = Array.isArray(lu) ? lu : Array.isArray(lu?.labels) ? lu.labels : null;
  if (liste === null) return null;
  return liste.map((etiquette) => (typeof etiquette === "string" ? etiquette : etiquette?.name)).filter((nom) => typeof nom === "string");
}

const aAccord = (etiquettes) => (etiquettes ?? []).some((nom) => nom.toLowerCase() === "accord");

/**
 * Le refus d'une fusion par l'outil MCP, ou null. `contexte` : { depot, releve, niveau, gardes, teteDistante }.
 * Rien ne se fusionne sans un relevé de la PR et de ses étiquettes, sans `expectedHeadSha` (GitHub refuse alors la
 * fusion si la branche a avancé) et sans la ligne `Niveau:` dans le commit de fusion.
 */
export function evaluerFusion(entree, { depot, releve, niveau, gardes, teteDistante, manquants = [] }) {
  if (`${entree.owner}/${entree.repo}` !== depot) return `ce dépôt est gouverné par la fiche de ${depot} ; ${entree.owner}/${entree.repo} a sa propre politique : travailler dans une session sur ce dépôt.`;
  if (entree.merge_method !== undefined && entree.merge_method !== "merge") return "une PR se fusionne par un commit de fusion : merge_method « merge » (pas squash ni rebase).";
  if (!releve) return `lire d'abord la PR : mcp__github__pull_request_read (method get, pullNumber ${entree.pullNumber}), puis mcp__github__issue_read (method get_labels, issue_number ${entree.pullNumber}).`;
  if (releve.labels == null) return `lire les étiquettes : mcp__github__issue_read (method get_labels, issue_number ${entree.pullNumber}).`;
  if (!entree.expectedHeadSha) return `ajouter expectedHeadSha: "${releve.tete}" (la tête relevée) : GitHub refuse alors la fusion si la branche a avancé depuis.`;
  if (entree.expectedHeadSha !== releve.tete) return `expectedHeadSha ne correspond pas au relevé (${releve.tete}) : relire la PR.`;
  if (teteDistante !== releve.tete) return `la branche ${releve.branche} a avancé depuis le relevé (${teteDistante}) : relire la PR, puis refaire la demande.`;
  if (manquants.length > 0) return `fusion refusée. ${messageCliquet(manquants)}`;
  const decision = decider({ niveau, methode: "merge", labels: releve.labels, accord: { parUnHumain: null, apresDernierCommit: null }, corps: releve.corps, gardes });
  if (!decision.permis) return `fusion refusée (niveau ${niveau}). ${decision.raison}`;
  if (!(entree.commit_message ?? "").split("\n").includes(ligneNiveau(niveau))) return `ajouter commit_message: "${ligneNiveau(niveau)}" : le commit de fusion porte son niveau.`;
  return null;
}

/** Refuse qu'un agent pose l'étiquette `accord` par l'outil d'écriture d'issue. */
export function evaluerEtiquettes(entree) {
  return aAccord(entree.labels) ? "l'étiquette « accord » est celle d'Antoine : lui seul la pose, sur GitHub. Un agent ne l'ajoute pas." : null;
}

/** Refuse, dans une commande, de poser `accord` avec `gh` ou d'envoyer du code sur une PR déjà acceptée. */
export function evaluerCommande(commande, { releves, brancheCourante }) {
  if (!/\bgit\s+push\b|\bgh\b/.test(commande)) return null;
  if (/\bgh\b/.test(commande) && /accord/i.test(commande) && /add-label|--label|label\b|labels/.test(commande)) {
    return "l'étiquette « accord » est celle d'Antoine : lui seul la pose, sur GitHub. Un agent ne l'ajoute pas.";
  }
  const suppression = /--delete|\s-d\s|\s:[^\s]/.test(commande);
  if (/\bgit\s+push\b/.test(commande) && !suppression && releves.some((releve) => releve.branche === brancheCourante && aAccord(releve.labels))) {
    return `la PR de la branche ${brancheCourante} a reçu l'étiquette « accord » : l'accord porte sur le code relu. Demander à Antoine de la retirer avant d'envoyer un nouveau commit.`;
  }
  return null;
}

/** `.claude/settings.json` : permissions étroites et hooks. `chemin` : le dossier qui contient garde.mjs. */
export function fabriquerReglages(chemin) {
  const commande = (option) => `node "$CLAUDE_PROJECT_DIR/${chemin}/garde.mjs" ${option}`;
  const reglages = {
    permissions: {
      allow: [
        "mcp__github__merge_pull_request",
        "mcp__github__pull_request_read",
        "mcp__github__issue_read",
        "mcp__github__issue_write",
        "mcp__github__update_pull_request",
        "mcp__github__create_pull_request",
        "Bash(git push origin --delete claude/*)",
        "Bash(git branch -D claude/*)",
      ],
      deny: [
        "Bash(gh pr merge*)",
        "Bash(git push --force*)",
        "Bash(git push * --force*)",
        "Bash(git push -f*)",
        "Bash(* --no-verify*)",
        "Bash(git push origin main*)",
        "Bash(git push origin HEAD:main*)",
        "mcp__github__push_files",
        "mcp__github__create_or_update_file",
        "mcp__github__delete_file",
        "mcp__github__enable_pr_auto_merge",
        "Edit(.claude/settings.json)",
        "Write(.claude/settings.json)",
        "Edit(.claude/sophos/**)",
        "Write(.claude/sophos/**)",
      ],
    },
    hooks: {
      PreToolUse: [
        {
          matcher: "Bash|mcp__github__merge_pull_request|mcp__github__issue_write|mcp__github__update_pull_request",
          hooks: [{ type: "command", command: commande("--garder"), timeout: 300 }],
        },
      ],
      PostToolUse: [
        { matcher: "mcp__github__pull_request_read|mcp__github__issue_read", hooks: [{ type: "command", command: commande("--noter"), timeout: 30 }] },
      ],
    },
  };
  return `${JSON.stringify(reglages, null, 2)}\n`;
}

/** `.githooks/pre-push` : Git le lance avant chaque envoi. `chemin` : le dossier qui contient garde.mjs. */
export function fabriquerPrePush(chemin) {
  return `#!/bin/sh
# Fabriqué par garde.mjs de Sophos ; ne pas modifier à la main.
# Git lance ce fichier avant chaque envoi, pour tout agent et pour une personne : les contrôles du projet,
# puis la recherche de secrets. Activer dans une copie du dépôt : git config core.hooksPath ${HOOKS_GIT}
exec node "$(git rev-parse --show-toplevel)/${chemin}/garde.mjs" --pousser
`;
}

/** Vrai quand l'envoi ne fait que supprimer des branches. `entree` : les lignes que Git donne à pre-push. */
export function supprimeSeulement(entree) {
  const lignes = entree.split("\n").filter((ligne) => ligne.trim() !== "");
  return lignes.length > 0 && lignes.every((ligne) => /^0+$/.test(ligne.split(" ")[1] ?? ""));
}

// ---------- Coquille : git, fichiers, entrée standard ----------
// (Un `git push` lance aussi `controler` de politique.mjs : le lanceur du projet, puis gitleaks.)

const racineProjet = () => process.env.CLAUDE_PROJECT_DIR ?? process.cwd();

function git(...arguments_) {
  return execFileSync("git", arguments_, { cwd: racineProjet(), encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim();
}

const dossierReleves = () => join(racineProjet(), git("rev-parse", "--git-path", "sophos"));
const cheminReleve = (numero) => join(dossierReleves(), `pr-${numero}.json`);

function lireReleve(numero) {
  try {
    return JSON.parse(readFileSync(cheminReleve(numero), "utf8"));
  } catch {
    return null;
  }
}

function lireReleves() {
  try {
    return readdirSync(dossierReleves()).filter((nom) => /^pr-\d+\.json$/.test(nom)).map((nom) => JSON.parse(readFileSync(join(dossierReleves(), nom), "utf8")));
  } catch {
    return [];
  }
}

function ecrireReleve(releve) {
  mkdirSync(dossierReleves(), { recursive: true });
  writeFileSync(cheminReleve(releve.numero), `${JSON.stringify(releve, null, 2)}\n`);
}

function lireEntree() {
  return JSON.parse(readFileSync(0, "utf8"));
}

function noter() {
  const { tool_name: outil, tool_input: entree = {}, tool_response: reponse } = lireEntree();
  const depot = entree.owner && entree.repo ? `${entree.owner}/${entree.repo}` : null;
  if (outil === "mcp__github__pull_request_read" && entree.method === "get") {
    const faits = faitsDePr(reponse);
    if (faits === null) return;
    ecrireReleve({ ...faits, depot, labels: lireReleve(faits.numero)?.labels ?? null });
  } else if (outil === "mcp__github__issue_read" && entree.method === "get_labels") {
    const etiquettes = etiquettesDe(reponse);
    if (etiquettes === null) return;
    ecrireReleve({ ...(lireReleve(entree.issue_number) ?? { numero: entree.issue_number }), depot, labels: etiquettes });
  }
}

/** Le refus voulu (texte) ou null. Toute panne remonte comme exception : elle ne bloque pas. */
function garder() {
  const { tool_name: outil, tool_input: entree = {} } = lireEntree();
  if (outil === "mcp__github__issue_write" || outil === "mcp__github__update_pull_request") return evaluerEtiquettes(entree);
  if (outil === "Bash") {
    const commande = entree.command ?? "";
    if (!/\bgit\s+push\b|\bgh\b/.test(commande)) return null;
    const brancheCourante = git("branch", "--show-current");
    const refus = evaluerCommande(commande, { releves: lireReleves(), brancheCourante });
    if (refus !== null || !/\bgit\s+push\b/.test(commande) || /--delete|\s-d\s|\s:[^\s]/.test(commande)) return refus;
    // Un push envoie du code : les contrôles du projet et la recherche de secrets passent d'abord. Quand le hook
    // Git est actif, c'est lui qui les lance : on ne les lance pas deux fois.
    if (hooksActifs()) return null;
    const base = lireReleves().find((releve) => releve.branche === brancheCourante)?.base ?? "main";
    return controler(racineProjet(), base);
  }
  if (outil !== "mcp__github__merge_pull_request") return null;
  const fiche = lireFiche(readFileSync(join(racineProjet(), FICHE), "utf8"));
  const releve = lireReleve(entree.pullNumber);
  let niveau = null;
  let manquants = [];
  let gardes = [];
  let teteDistante = null;
  if (releve) {
    git("fetch", "--quiet", "origin", releve.base, releve.branche);
    teteDistante = git("rev-parse", `origin/${releve.branche}`);
    gardes = politiqueA(`origin/${releve.base}`, `origin/${releve.base}`).gardes;
    ({ niveau, manquants } = classerRef(`origin/${releve.branche}`, releve.base));
  }
  return evaluerFusion(entree, { depot: fiche.depot, releve, niveau, gardes, teteDistante, manquants });
}

/** Le dossier de hooks que Git lit dans cette copie, ou "" quand rien n'est réglé. */
function dossierHooks() {
  try {
    return git("config", "--get", "core.hooksPath");
  } catch {
    return "";
  }
}

const hooksActifs = () => dossierHooks() === HOOKS_GIT;

/** Hook Git pre-push : le refus (texte) ou null. Supprimer une branche n'envoie pas de code. */
function pousser() {
  if (supprimeSeulement(readFileSync(0, "utf8"))) return null;
  return controler(racineProjet());
}

/**
 * Active le hook Git dans cette copie. N'écrase jamais des hooks qui existent : rend alors la phrase qui dit quoi faire.
 * Rend null quand il n'y a rien à dire.
 */
function activerHooks(racine) {
  let actuel;
  let propres;
  try {
    actuel = execFileSync("git", ["config", "--get", "core.hooksPath"], { cwd: racine, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch {
    actuel = "";
  }
  if (actuel === HOOKS_GIT) return null;
  try {
    const dossier = execFileSync("git", ["rev-parse", "--git-path", "hooks"], { cwd: racine, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
    propres = actuel === "" && existsSync(join(racine, dossier)) && readdirSync(join(racine, dossier)).some((nom) => !nom.endsWith(".sample"));
  } catch {
    return null; // pas un dépôt Git : rien à activer
  }
  if (actuel !== "" || propres) {
    return `Ce dépôt a déjà ses hooks Git (${actuel || ".git/hooks"}) : la garde n'y touche pas. Ajouter à son pre-push la ligne : sh ${PRE_PUSH}`;
  }
  execFileSync("git", ["config", "core.hooksPath", HOOKS_GIT], { cwd: racine });
  return `Hook Git activé dans cette copie (core.hooksPath ${HOOKS_GIT}).`;
}

// ---------- Réglage d'un dépôt ----------

function emplacement(racine) {
  const dansSophos = existsSync(join(racine, "outils")) && realpathSync(join(racine, "outils")) === realpathSync(OUTILS);
  return dansSophos ? "outils" : COPIES;
}

/** Les fichiers que le réglage attend : [{ chemin, contenu }]. */
function attendus(racine) {
  const chemin = emplacement(racine);
  const fichiers = [
    { chemin: join(racine, REGLAGES), contenu: fabriquerReglages(chemin) },
    { chemin: join(racine, PRE_PUSH), contenu: fabriquerPrePush(chemin) },
  ];
  if (chemin === COPIES) {
    for (const nom of OUTILS_COPIES) fichiers.push({ chemin: join(racine, COPIES, nom), contenu: readFileSync(join(OUTILS, nom), "utf8") });
  }
  return fichiers;
}

function regler(racine, { ecrire }) {
  if (!existsSync(join(racine, FICHE))) throw new ErreurPolitique(`${FICHE} manque à la racine de ${racine}.`);
  const differents = attendus(racine).filter(({ chemin, contenu }) => !existsSync(chemin) || readFileSync(chemin, "utf8") !== contenu);
  if (!ecrire) {
    if (differents.length > 0) {
      throw new ErreurPolitique(`Réglage des agents à refaire : ${differents.map(({ chemin }) => chemin.slice(racine.length + 1)).join(", ")}.\nLancer : node <sophos>/outils/garde.mjs`);
    }
    return "Réglage des agents à jour.";
  }
  for (const { chemin, contenu } of differents) {
    mkdirSync(dirname(chemin), { recursive: true });
    writeFileSync(chemin, contenu);
  }
  chmodSync(join(racine, PRE_PUSH), 0o755);
  const activation = activerHooks(racine);
  if (activation !== null) console.error(activation);
  return differents.length > 0 ? `Réglage écrit : ${differents.map(({ chemin }) => chemin.slice(racine.length + 1)).join(", ")}.` : "Réglage déjà à jour.";
}

function lancer(arguments_) {
  const option = arguments_[0];
  if (arguments_.length > 1 || ![undefined, "--verifier", "--noter", "--garder", "--pousser"].includes(option)) {
    console.error("Usage : node garde.mjs [--verifier | --noter | --garder | --pousser]");
    return 2;
  }
  if (option === "--noter") {
    noter();
    return 0;
  }
  if (option === "--garder") {
    const refus = garder();
    if (refus === null) return 0;
    console.error(`Refusé : ${refus}`);
    return 2;
  }
  if (option === "--pousser") {
    const refus = pousser();
    if (refus === null) return 0;
    console.error(`Envoi refusé : ${refus}\nUne personne peut passer outre en cas d'urgence : git push --no-verify. Un agent ne le fait pas.`);
    return 1;
  }
  console.log(regler(process.cwd(), { ecrire: option === undefined }));
  return 0;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const hook = ["--noter", "--garder"].includes(process.argv[2]);
  try {
    process.exitCode = lancer(process.argv.slice(2));
  } catch (erreur) {
    console.error(erreur instanceof ErreurPolitique || erreur instanceof ErreurFiche ? erreur.message : `garde.mjs : ${erreur.message}`);
    if (process.argv[2] === "--pousser") console.error("Le hook Git est en panne : les contrôles n'ont pas tourné. L'envoi continue ; lancer les contrôles à la main.");
    // Une panne d'un hook ne bloque pas l'agent (code 1) ; une commande lancée à la main échoue normalement.
    process.exitCode = process.argv[2] === "--pousser" ? 0 : 1;
    if (!hook && process.argv[2] !== "--pousser" && !(erreur instanceof ErreurPolitique || erreur instanceof ErreurFiche)) throw erreur;
  }
}
