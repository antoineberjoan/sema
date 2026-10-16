"use strict";

const indicators = [
  { name: "France · 10 ans", category: "Taux souverain", icon: "↗", aliases: "oat france obligation taux souverain", description: "Le taux de référence des obligations françaises à dix ans. Série mensuelle publiée sur Webstat." },
  { name: "BCE · Facilité de dépôt", category: "Taux directeur", icon: "%", aliases: "banque centrale europeenne bce depot directeur", description: "Le taux de la facilité de dépôt de la Banque centrale européenne. L’historique permet de retrouver les changements de taux." },
  { name: "Crédit immobilier", category: "Crédit · France", icon: "⌂", aliases: "immobilier emprunt pret habitat logement credit", description: "Le taux moyen des nouveaux crédits à l’habitat en France, hors renégociations. Une série mensuelle, distincte d’une offre bancaire ou d’un TAEG." },
  { name: "Inflation · France", category: "Prix · France", icon: "%", aliases: "inflation france ipch prix", description: "La variation annuelle de l’indice des prix à la consommation harmonisé en France. Données Eurostat, diffusées via Webstat." },
  { name: "Euro / Dollar", category: "Devise · EUR / USD", icon: "$", aliases: "eur usd dollar change americain euro", description: "Le taux de change de référence du dollar américain pour un euro. Il suit le calendrier de publication de la série, sans cotation en continu." },
  { name: "€STR", category: "Taux monétaire", icon: "%", aliases: "estr court terme monetaire euro", description: "Le taux à court terme en euros, publié chaque jour ouvré selon le calendrier de la série." },
  { name: "Inflation · Zone euro", category: "Prix · Zone euro", icon: "%", aliases: "inflation europe zone euro ipch prix", description: "La variation annuelle de l’indice des prix à la consommation harmonisé dans la zone euro. Données Eurostat, diffusées via Webstat." },
  { name: "Livret A", category: "Épargne réglementée", icon: "%", aliases: "livret a epargne taux reglemente", description: "Le taux du Livret A et ses évolutions historiques, pour replacer la rémunération de l’épargne dans son contexte." },
  { name: "LDDS", category: "Épargne réglementée", icon: "%", aliases: "ldds livret developpement durable solidaire epargne", description: "Le taux du livret de développement durable et solidaire, avec les observations historiques disponibles sur Webstat." },
  { name: "LEP", category: "Épargne réglementée", icon: "%", aliases: "lep livret epargne populaire", description: "Le taux du livret d’épargne populaire et son évolution dans le temps." },
  { name: "Euro / Yen", category: "Devise · EUR / JPY", icon: "¥", aliases: "eur jpy yen japon change euro", description: "Le taux de change de référence du yen japonais pour un euro, avec un historique consultable dans Sema." },
  { name: "Euro / Franc suisse", category: "Devise · EUR / CHF", icon: "↔", aliases: "eur chf franc suisse change euro", description: "Le taux de change de référence du franc suisse pour un euro, selon les publications de la série." },
  { name: "Euro / Livre sterling", category: "Devise · EUR / GBP", icon: "£", aliases: "eur gbp livre sterling royaume uni change euro", description: "Le taux de change de référence de la livre sterling pour un euro, avec l’historique disponible sur Webstat." }
];

const searchInput = document.querySelector("#rate-search");
const resultsContainer = document.querySelector("#rate-results");
const resultCount = document.querySelector("#result-count");
const emptyState = document.querySelector(".no-results");
const indicatorDialog = document.querySelector("#indicator-dialog");
const screenshotDialog = document.querySelector("#screenshot-dialog");
let activeIndex = 0;
let visibleIndicators = [];

const normalized = (value) => value.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();

function openIndicator(indicator) {
  document.querySelector("#indicator-title").textContent = indicator.name;
  document.querySelector("#indicator-description").textContent = indicator.description;
  indicatorDialog.showModal();
}

function setActive(index) {
  activeIndex = index;
  Array.from(resultsContainer.children).forEach((button, position) => {
    button.classList.toggle("active", position === index);
  });
}

function renderResults() {
  const query = normalized(searchInput.value.trim());
  const matches = indicators.filter((item) => normalized(`${item.name} ${item.category} ${item.aliases}`).includes(query));
  visibleIndicators = matches.slice(0, 5);
  activeIndex = 0;
  resultsContainer.replaceChildren();
  visibleIndicators.forEach((indicator, index) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "rate-result";
    const icon = document.createElement("span");
    icon.className = "result-icon";
    icon.setAttribute("aria-hidden", "true");
    icon.textContent = indicator.icon;
    const text = document.createElement("span");
    const name = document.createElement("span");
    name.className = "result-name";
    name.textContent = indicator.name;
    const category = document.createElement("span");
    category.className = "result-category";
    category.textContent = indicator.category;
    const arrow = document.createElement("span");
    arrow.className = "result-arrow";
    arrow.textContent = "↵";
    arrow.setAttribute("aria-hidden", "true");
    text.append(name, category);
    button.append(icon, text, arrow);
    button.addEventListener("click", () => { setActive(index); openIndicator(indicator); });
    button.addEventListener("focus", () => setActive(index));
    resultsContainer.append(button);
  });
  emptyState.hidden = matches.length > 0;
  resultCount.textContent = query ? `${matches.length} repère${matches.length === 1 ? "" : "s"}` : "13 repères";
  setActive(0);
}

searchInput.addEventListener("input", renderResults);
searchInput.addEventListener("keydown", (event) => {
  if ((event.key === "ArrowDown" || event.key === "ArrowUp") && visibleIndicators.length) {
    event.preventDefault();
    setActive(event.key === "ArrowDown" ? 0 : visibleIndicators.length - 1);
    resultsContainer.children[activeIndex].focus();
  } else if (event.key === "Enter" && visibleIndicators[activeIndex]) {
    event.preventDefault();
    openIndicator(visibleIndicators[activeIndex]);
  } else if (event.key === "Escape") {
    searchInput.value = "";
    renderResults();
    searchInput.blur();
  }
});

resultsContainer.addEventListener("keydown", (event) => {
  if (event.key === "ArrowDown" || event.key === "ArrowUp") {
    event.preventDefault();
    const next = (activeIndex + (event.key === "ArrowDown" ? 1 : -1) + visibleIndicators.length) % visibleIndicators.length;
    resultsContainer.children[next].focus();
  } else if (event.key === "Escape") {
    searchInput.focus();
  }
});

document.addEventListener("keydown", (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k" && !document.querySelector("dialog[open]")) {
    event.preventDefault();
    searchInput.focus({ preventScroll: true });
    searchInput.scrollIntoView({ block: "center", behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "instant" : "smooth" });
  }
});

document.querySelectorAll("[data-enlarge]").forEach((button) => {
  button.addEventListener("click", () => screenshotDialog.showModal());
});

document.querySelectorAll("dialog").forEach((dialog) => {
  dialog.addEventListener("click", (event) => {
    const rect = dialog.getBoundingClientRect();
    if (event.target === dialog && (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom)) dialog.close();
  });
});

renderResults();
