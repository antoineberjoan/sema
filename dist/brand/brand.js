"use strict";

/* ANIMATION STORYBOARD
 *
 *    0ms   action: update its state immediately
 *  120ms   feedback has settled; no delayed local result
 *  180ms   selection background has settled
 *  240ms   panel: opacity 0 → 1, y 8 → 0, scale .985 → 1
 *  900ms   brand signature finishes once, only in this guide
 *
 * The lab exposes duration and travel. All running animations can be cancelled.
 * Reduced motion shows the final state immediately. No timers hide information.
 */
const MOTION = {
  panel: { duration: 240, distance: 8, scale: .985, easing: "cubic-bezier(.22,1,.36,1)" },
  signature: { duration: 900, easing: "cubic-bezier(.22,1,.36,1)" },
  selection: { duration: 180 },
};
const THEMES = [
  {name:"Graphite", light:"#474747", dark:"#D6D6D6"},
  {name:"Sarcelle", light:"#1F6F73", dark:"#9AD0C2"},
  {name:"Menthe", light:"#32755E", dark:"#9ED5C5"},
  {name:"Lavande", light:"#78499E", dark:"#D0A2F7"},
  {name:"Bleu ciel", light:"#007AB8", dark:"#89CFF3"},
  {name:"Bleu polaire", light:"#097BAF", dark:"#90D2F5"},
];
const preference = matchMedia("(prefers-reduced-motion: reduce)");
const reduceToggle = document.querySelector("#reduce-motion");
reduceToggle.checked = preference.matches;
const reduced = () => preference.matches || reduceToggle.checked;
const preview = document.querySelector("#theme-preview");
const picker = document.querySelector(".theme-picker");
let selectedTheme = THEMES[0];
let light = false;

function applyTheme() {
  preview.style.setProperty("--theme", light ? selectedTheme.light : selectedTheme.dark);
  preview.style.setProperty("--control", selectedTheme.light);
  preview.classList.toggle("light", light);
  document.querySelector("#theme-note").textContent = `${selectedTheme.name} · accent ${light ? "clair" : "sombre"} ${light ? selectedTheme.light : selectedTheme.dark}`;
  picker.querySelectorAll("button").forEach(button => button.setAttribute("aria-pressed", String(button.dataset.name === selectedTheme.name)));
}
THEMES.forEach(theme => {
  const button = document.createElement("button");
  button.type = "button";
  button.dataset.name = theme.name;
  button.title = theme.name;
  button.setAttribute("aria-label", theme.name);
  button.style.setProperty("--chip", theme.dark);
  button.addEventListener("click", () => { selectedTheme = theme; applyTheme(); });
  picker.append(button);
});
document.querySelector("#appearance").addEventListener("click", event => {
  light = !light;
  event.currentTarget.setAttribute("aria-pressed", String(light));
  event.currentTarget.textContent = light ? "Passer en sombre" : "Passer en clair";
  applyTheme();
});
applyTheme();
document.querySelector("#favorite").addEventListener("click", event => {
  const active = event.currentTarget.getAttribute("aria-pressed") !== "true";
  event.currentTarget.setAttribute("aria-pressed", String(active));
  event.currentTarget.textContent = active ? "Ajouté aux favoris ✓" : "Ajouter aux favoris";
});

const sections = {
  Panorama: ["Vos repères, réunis.","Un élément sélectionné, une surface principale et de l’espace autour."],
  Favoris: ["L’essentiel, pour vous.","Retrouver les indicateurs choisis. La sélection reste locale sur votre Mac."],
  Alertes: ["Le seuil qui compte.","Une règle claire, vérifiée quand vous actualisez les données dans l’app."],
};
document.querySelectorAll("[data-section]").forEach(button => button.addEventListener("click", () => {
  const name = button.dataset.section;
  document.querySelectorAll("[data-section]").forEach(row => {
    row.classList.toggle("selected", row === button);
    row.setAttribute("aria-pressed", String(row === button));
  });
  document.querySelector("#section-name").textContent = name;
  document.querySelector("#section-title").textContent = sections[name][0];
  document.querySelector("#section-copy").textContent = sections[name][1];
}));

const panel = document.querySelector("#motion-panel");
const duration = document.querySelector("#duration");
const distance = document.querySelector("#distance");
let panelAnimation;
let signatureAnimation;
let dialogAnimation;
function updateMotionLabels() {
  document.querySelector("#duration-value").value = `${duration.value} ms`;
  document.querySelector("#distance-value").value = `${distance.value} px`;
  document.querySelector("#motion-status").textContent = reduced()
    ? "Animation réduite : état final immédiat, sans déplacement ni changement d’échelle."
    : `Entrée : ${duration.value} ms · ${distance.value} px · décélération douce.`;
}
function replayPanel() {
  // A rapid adjustment continues from the rendered frame, without a jump to zero.
  const current = panelAnimation?.playState === "running" ? getComputedStyle(panel) : null;
  const initial = current
    ? { opacity: current.opacity, transform: current.transform }
    : { opacity: 0, transform: `translateY(${distance.value}px) scale(${MOTION.panel.scale})` };
  panelAnimation?.cancel();
  updateMotionLabels();
  if (reduced()) return;
  panelAnimation = panel.animate([
    initial,
    { opacity: 1, transform: "translateY(0) scale(1)" }
  ], { duration: Number(duration.value), easing: MOTION.panel.easing });
}
duration.addEventListener("input", replayPanel);
distance.addEventListener("input", replayPanel);
document.querySelector("#replay").addEventListener("click", replayPanel);
document.querySelector("#reset-motion").addEventListener("click", () => {
  duration.value = MOTION.panel.duration;
  distance.value = MOTION.panel.distance;
  replayPanel();
});
function applyReducedMotion() {
  document.documentElement.dataset.reducedMotion = String(reduced());
  if (reduced()) {
    panelAnimation?.cancel(); signatureAnimation?.cancel(); dialogAnimation?.cancel();
  }
  updateMotionLabels();
}
reduceToggle.addEventListener("change", applyReducedMotion);
preference.addEventListener("change", () => {
  reduceToggle.checked = preference.matches;
  applyReducedMotion();
});
const signature = document.querySelector(".signature-path");
if (!reduced()) {
  const length = signature.getTotalLength();
  signatureAnimation = signature.animate([
    { strokeDasharray: `${length}`, strokeDashoffset: length },
    { strokeDasharray: `${length}`, strokeDashoffset: 0 }
  ], { duration: MOTION.signature.duration, easing: MOTION.signature.easing });
}
updateMotionLabels();

const dialog = document.querySelector("#search-dialog");
const search = document.querySelector("#brand-search");
const results = document.querySelector("#brand-results");
const indicators = [
  {name:"France 10 ans", aliases:"oat taux obligataire"},
  {name:"Taux de dépôt BCE", aliases:"banque centrale"},
  {name:"Crédit immobilier", aliases:"emprunt prêt habitation"},
  {name:"Inflation France", aliases:"prix ipch"},
  {name:"Euro / Dollar", aliases:"eur usd devises"},
];
const normalize = value => value.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
function renderResults() {
  results.replaceChildren();
  const query = normalize(search.value.trim());
  indicators.filter(item => normalize(item.name + " " + item.aliases).includes(query)).forEach(item => {
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = item.name;
    button.addEventListener("click", () => {
      document.querySelector("#search-status").textContent = `${item.name} sélectionné dans la démonstration.`;
    });
    results.append(button);
  });
  document.querySelector("#search-status").textContent = results.childElementCount ? "" : "Aucun repère trouvé. Essayez « BCE » ou « immobilier ».";
}
function openSearch() {
  if (dialog.open) { search.focus(); return; }
  search.value = "";
  renderResults();
  dialog.showModal();
  search.focus();
  dialogAnimation?.cancel();
  if (!reduced()) dialogAnimation = dialog.animate([
    { opacity: 0, transform: `translateY(${MOTION.panel.distance}px) scale(${MOTION.panel.scale})` },
    { opacity: 1, transform: "translateY(0) scale(1)" }
  ], { duration: MOTION.panel.duration, easing: MOTION.panel.easing });
}
document.querySelector("#open-search").addEventListener("click", openSearch);
search.addEventListener("input", renderResults);
dialog.addEventListener("close", () => dialogAnimation?.cancel());
dialog.addEventListener("keydown", event => {
  const buttons = [...results.querySelectorAll("button")];
  const index = buttons.indexOf(document.activeElement);
  if (event.key === "ArrowDown" && buttons.length) { event.preventDefault(); buttons[(index + 1) % buttons.length].focus(); }
  if (event.key === "ArrowUp" && buttons.length) { event.preventDefault(); (index <= 0 ? search : buttons[index - 1]).focus(); }
  if (event.key === "Enter" && document.activeElement === search && buttons.length) { event.preventDefault(); buttons[0].click(); }
});
document.addEventListener("keydown", event => {
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") { event.preventDefault(); openSearch(); }
});
