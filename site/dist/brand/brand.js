"use strict";

/* Le guide anime le thème d'aperçu et trace la signature une fois.
 * Réduire les animations affiche directement le signe complet.
 */
const SIGNATURE = { duration: 900, easing: "cubic-bezier(.22,1,.36,1)" };
const THEMES = [
  {name:"Graphite", light:"#474747", dark:"#D6D6D6"},
  {name:"Sarcelle", light:"#1F6F73", dark:"#9AD0C2"},
  {name:"Menthe", light:"#32755E", dark:"#9ED5C5"},
  {name:"Lavande", light:"#78499E", dark:"#D0A2F7"},
  {name:"Bleu ciel", light:"#007AB8", dark:"#89CFF3"},
  {name:"Bleu polaire", light:"#097BAF", dark:"#90D2F5"},
];
const preference = matchMedia("(prefers-reduced-motion: reduce)");
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


const signature = document.querySelector(".signature-path");
if (!preference.matches) {
  const length = signature.getTotalLength();
  signature.animate([
    { strokeDasharray: `${length}`, strokeDashoffset: length },
    { strokeDasharray: `${length}`, strokeDashoffset: 0 }
  ], { duration: SIGNATURE.duration, easing: SIGNATURE.easing });
}
