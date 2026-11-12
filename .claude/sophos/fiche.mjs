// La fiche d'un dépôt (fonder § 5) : lecture de `projet.yml` et contrôle de ses champs. Le contrat
// de la fiche vit ici, une seule fois ; `carte.mjs` et `politique.mjs` l'importent. Aucune dépendance.

import { existsSync } from "node:fs";
import { join } from "node:path";

export const FICHE = "projet.yml";
export const ETATS = ["actif", "en pause", "archivé"];
export const SENS_DES_LIENS = {
  lit: "Lit",
  alimente: "Alimente",
  applique: "Applique",
  distribue: "Distribue",
  "est-distribue-par": "Est distribué par",
};

export const NIVEAUX = ["vert", "orange", "rouge"];
export const GARDES = ["controles", "niveau"];

export class ErreurFiche extends Error {}

/** La version de Sophos qu'un projet suit (`sophos:` dans sa fiche). Sans ce champ : 1, la forme d'avant la refonte. */
export const versionSuivie = (fiche) => Number(fiche.sophos ?? 1);

function echouer(message) {
  throw new ErreurFiche(message);
}

// ---------- Lecture de la fiche : un sous-ensemble strict de YAML ----------
// Clés `nom: valeur`, cartes imbriquées par deux espaces, listes `[a, b]`, cartes `{ a: b }`.
// Tout le reste est refusé avec son numéro de ligne : la fiche reste simple à lire et à écrire.

function lireScalaire(texte, ligne) {
  const valeur = texte.trim();
  if (valeur === "") echouer(`${FICHE}, ligne ${ligne} : valeur vide.`);
  const guillemets = valeur.match(/^"(.*)"$/);
  return guillemets ? guillemets[1] : valeur;
}

function lireValeur(texte, ligne) {
  const valeur = texte.trim();
  if (valeur.startsWith("[")) {
    if (!valeur.endsWith("]")) echouer(`${FICHE}, ligne ${ligne} : liste non fermée.`);
    const interieur = valeur.slice(1, -1).trim();
    return interieur === "" ? [] : interieur.split(",").map((element) => lireScalaire(element, ligne));
  }
  if (valeur.startsWith("{")) {
    if (!valeur.endsWith("}")) echouer(`${FICHE}, ligne ${ligne} : carte non fermée.`);
    const carte = {};
    for (const paire of valeur.slice(1, -1).split(",")) {
      const separateur = paire.indexOf(":");
      if (separateur < 0) echouer(`${FICHE}, ligne ${ligne} : « ${paire.trim()} » n'a pas la forme clé: valeur.`);
      carte[paire.slice(0, separateur).trim()] = lireScalaire(paire.slice(separateur + 1), ligne);
    }
    return carte;
  }
  return lireScalaire(valeur, ligne);
}

export function lireFiche(texte) {
  const racine = {};
  const pile = [{ retrait: -1, carte: racine }];
  texte.split("\n").forEach((brute, index) => {
    const ligne = index + 1;
    const sansCommentaire = brute.replace(/(^|\s)#.*$/, "").replace(/\s+$/, "");
    if (sansCommentaire.trim() === "") return;
    const retrait = sansCommentaire.length - sansCommentaire.trimStart().length;
    if (retrait % 2 !== 0) echouer(`${FICHE}, ligne ${ligne} : retrait de ${retrait} espaces, attendu un multiple de 2.`);
    const contenu = sansCommentaire.trim();
    const separateur = contenu.indexOf(":");
    if (separateur <= 0) echouer(`${FICHE}, ligne ${ligne} : « ${contenu} » n'a pas la forme clé: valeur.`);
    const cle = contenu.slice(0, separateur).trim();
    const reste = contenu.slice(separateur + 1);
    while (pile.at(-1).retrait >= retrait) pile.pop();
    const parent = pile.at(-1);
    if (retrait !== parent.retrait + 2 && !(parent.retrait === -1 && retrait === 0)) {
      echouer(`${FICHE}, ligne ${ligne} : retrait inattendu.`);
    }
    if (cle in parent.carte) echouer(`${FICHE}, ligne ${ligne} : clé « ${cle} » en double.`);
    if (reste.trim() === "") {
      parent.carte[cle] = {};
      pile.push({ retrait, carte: parent.carte[cle] });
    } else {
      parent.carte[cle] = lireValeur(reste, ligne);
    }
  });
  return racine;
}

// ---------- Contrôle de la fiche ----------

export function verifierCles(objet, permises, ou) {
  for (const cle of Object.keys(objet)) {
    if (!permises.includes(cle)) echouer(`${FICHE} : clé inconnue « ${cle} » dans ${ou}. Clés permises : ${permises.join(", ")}.`);
  }
}

export function exiger(objet, cle, ou) {
  const valeur = objet[cle];
  if (typeof valeur !== "string" || valeur === "") echouer(`${FICHE} : « ${cle} » manque ou est vide dans ${ou}.`);
  if (valeur.startsWith("[à écrire")) echouer(`${FICHE} : « ${cle} » porte encore le texte du gabarit dans ${ou}. L'écrire : ${valeur}`);
  return valeur;
}

export function verifierFiche(fiche, racine) {
  verifierCles(fiche, ["nom", "depot", "role", "raison", "etat", "sorte", "adresse", "version", "sophos", "liens", "skills", "marque", "politique", "structure"], "la fiche");
  exiger(fiche, "nom", "la fiche");
  if (!/^[\w.-]+\/[\w.-]+$/.test(exiger(fiche, "depot", "la fiche"))) echouer(`${FICHE} : « depot » doit avoir la forme propriétaire/nom.`);
  if (!exiger(fiche, "role", "la fiche").endsWith(".")) echouer(`${FICHE} : « role » est une phrase, elle finit par un point.`);
  for (const cle of ["version", "sophos"]) {
    if (fiche[cle] !== undefined && !/^[1-9]\d*$/.test(fiche[cle])) echouer(`${FICHE} : « ${cle} » est un nombre entier (1, 2, 3…).`);
  }
  if (versionSuivie(fiche) >= 2 || fiche.raison !== undefined) {
    if (!exiger(fiche, "raison", "la fiche").endsWith(".")) echouer(`${FICHE} : « raison » est une phrase, elle finit par un point. Elle dit pourquoi le projet existe ; « role » dit ce qu'il est.`);
  }
  if (!ETATS.includes(exiger(fiche, "etat", "la fiche"))) echouer(`${FICHE} : « etat » vaut ${ETATS.join(", ")}.`);
  exiger(fiche, "sorte", "la fiche");
  if (fiche.adresse !== undefined && !/^https:\/\/\S+$/.test(fiche.adresse)) echouer(`${FICHE} : « adresse » commence par https://.`);
  const liens = fiche.liens ?? {};
  if (typeof liens !== "object" || Array.isArray(liens)) echouer(`${FICHE} : « liens » est une carte sens: [dépôts].`);
  verifierCles(liens, Object.keys(SENS_DES_LIENS), "liens");
  for (const [sens, depots] of Object.entries(liens)) {
    if (!Array.isArray(depots) || depots.length === 0) echouer(`${FICHE} : liens.${sens} est une liste non vide de dépôts.`);
  }
  if (fiche.skills !== undefined) {
    if (!Array.isArray(fiche.skills) || fiche.skills.length === 0) echouer(`${FICHE} : « skills » est une liste non vide de skills de Sophos, par exemple [penser, construire].`);
    for (const nom of fiche.skills) if (!/^[a-z]+$/.test(nom)) echouer(`${FICHE} : skills : « ${nom} » n'est pas un nom de skill (minuscules, sans accent).`);
    if (new Set(fiche.skills).size !== fiche.skills.length) echouer(`${FICHE} : skills : un skill est écrit deux fois.`);
  }
  if (fiche.marque === undefined) echouer(`${FICHE} : « marque » manque. La marque par défaut n'est pas encore définie dans Sophos.`);
  const marque = fiche.marque;
  verifierCles(marque, ["tokens", "icone-claire", "icone-sombre", "capture-claire", "capture-sombre", "clair", "sombre"], "marque");
  const icones = ["icone-claire", "icone-sombre"].filter((chemin) => marque[chemin] !== undefined);
  if (icones.length === 1) echouer(`${FICHE} : marque.icone-claire et marque.icone-sombre vont ensemble : donner les deux, ou aucune.`);
  const captures = ["capture-claire", "capture-sombre"].filter((chemin) => marque[chemin] !== undefined);
  if (captures.length === 1) echouer(`${FICHE} : marque.capture-claire et marque.capture-sombre vont ensemble : donner les deux, ou aucune.`);
  for (const chemin of ["tokens", ...icones, ...captures]) {
    if (!existsSync(join(racine, exiger(marque, chemin, "marque")))) echouer(`${FICHE} : marque.${chemin} vise un fichier absent : ${marque[chemin]}.`);
  }
  for (const theme of ["clair", "sombre"]) {
    const couleurs = marque[theme];
    if (typeof couleurs !== "object" || Array.isArray(couleurs)) echouer(`${FICHE} : marque.${theme} est une carte { fond, texte, accent }.`);
    verifierCles(couleurs, ["fond", "texte", "accent"], `marque.${theme}`);
    const enJson = marque.tokens.endsWith(".json");
    for (const role of ["fond", "texte", "accent"]) {
      const nom = exiger(couleurs, role, `marque.${theme}`);
      if (enJson && !/^[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(nom)) echouer(`${FICHE} : marque.${theme}.${role} est le chemin d'un jeton de tokens.json (color.background).`);
      if (!enJson && !/^--[\w-]+$/.test(nom)) echouer(`${FICHE} : marque.${theme}.${role} est un nom de token (--nom).`);
    }
  }
  if (fiche.politique !== undefined) verifierPolitique(fiche.politique, racine);
  return fiche;
}

// ---------- La section « politique » : niveaux de risque (fonder § 6) ----------
// Un motif est un chemin avec `*` (dans un segment), `**` (un segment entier, zéro ou plusieurs
// segments) et `?`. Tout le reste est refusé : une seule grammaire, la nôtre, pour tous les dépôts.

export function verifierGlob(glob, ou) {
  if (typeof glob !== "string" || glob === "") echouer(`${FICHE} : ${ou} contient un motif vide.`);
  if (/[{}\[\]!,]/.test(glob)) echouer(`${FICHE} : motif « ${glob} » dans ${ou} : seuls *, ** et ? sont permis (pas de { } [ ] ! ,).`);
  if (glob.startsWith("/") || glob.startsWith("./")) echouer(`${FICHE} : motif « ${glob} » dans ${ou} : un chemin relatif à la racine, sans « / » ni « ./ » au début.`);
  if (glob.endsWith("/")) echouer(`${FICHE} : motif « ${glob} » dans ${ou} : pas de « / » final ; écrire « ${glob}** » pour tout un dossier.`);
  if (glob.split("/").some((segment) => segment.includes("**") && segment !== "**")) {
    echouer(`${FICHE} : motif « ${glob} » dans ${ou} : « ** » occupe un segment entier.`);
  }
}

export function verifierPolitique(politique, racine = null) {
  if (typeof politique !== "object" || Array.isArray(politique)) echouer(`${FICHE} : « politique » est une carte.`);
  verifierCles(politique, ["defaut", "vert", "orange", "rouge", "gardes", "controle", "cliquet"], "politique");
  const defaut = exiger(politique, "defaut", "politique");
  if (!NIVEAUX.includes(defaut)) echouer(`${FICHE} : politique.defaut vaut ${NIVEAUX.join(", ")}.`);
  const vus = new Map();
  for (const niveau of NIVEAUX) {
    const liste = politique[niveau];
    if (liste === undefined) continue;
    if (!Array.isArray(liste) || liste.length === 0) echouer(`${FICHE} : politique.${niveau} est une liste non vide de motifs.`);
    if (niveau === defaut) echouer(`${FICHE} : politique.${niveau} est le niveau par défaut : cette liste ne change rien, la retirer.`);
    for (const glob of liste) {
      verifierGlob(glob, `politique.${niveau}`);
      if (vus.has(glob)) echouer(`${FICHE} : motif « ${glob} » écrit dans politique.${vus.get(glob)} et politique.${niveau} : un motif ne s'écrit qu'une fois.`);
      vus.set(glob, niveau);
    }
  }
  if (politique.gardes !== undefined) {
    if (!Array.isArray(politique.gardes)) echouer(`${FICHE} : politique.gardes est une liste parmi ${GARDES.join(", ")}.`);
    for (const garde of politique.gardes) {
      if (!GARDES.includes(garde)) echouer(`${FICHE} : politique.gardes : « ${garde} » inconnu. Valeurs : ${GARDES.join(", ")}.`);
    }
  }
  const controle = exiger(politique, "controle", "politique");
  if (!controle.startsWith("./")) echouer(`${FICHE} : politique.controle est un chemin qui commence par « ./ » (le lanceur unique du projet).`);
  if (racine !== null && !existsSync(join(racine, controle))) echouer(`${FICHE} : politique.controle vise un fichier absent : ${controle}.`);
  if (politique.cliquet !== undefined) {
    if (typeof politique.cliquet !== "object" || Array.isArray(politique.cliquet)) echouer(`${FICHE} : politique.cliquet est une carte chemin: { niveau, fusion }.`);
    for (const [chemin, entree] of Object.entries(politique.cliquet)) {
      if (/[*?]/.test(chemin) || chemin.startsWith("/") || chemin.startsWith("./")) echouer(`${FICHE} : politique.cliquet : « ${chemin} » est un fichier exact, relatif à la racine, sans « * » ni « ? ». Un motif large est un choix d'Antoine, dans politique.orange ou politique.rouge.`);
      if (typeof entree !== "object" || Array.isArray(entree)) echouer(`${FICHE} : politique.cliquet.${chemin} est { niveau: orange, fusion: <commit> }.`);
      verifierCles(entree, ["niveau", "fusion"], `politique.cliquet.${chemin}`);
      if (!["orange", "rouge"].includes(entree.niveau)) echouer(`${FICHE} : politique.cliquet.${chemin}.niveau vaut orange ou rouge (le cliquet ne fait que monter).`);
      if (!/^[0-9a-f]{7,40}$/.test(entree.fusion ?? "")) echouer(`${FICHE} : politique.cliquet.${chemin}.fusion est l'identifiant (7 à 40 chiffres hexadécimaux) de la fusion annulée.`);
    }
  }
}
