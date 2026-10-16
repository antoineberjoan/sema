"use strict";

/* ANIMATION STORYBOARD — one demonstration, never an installation progress bar.
 *
 *    0ms   composition visible; actions already usable
 *  120ms   Palier draws, dash offset 1 → 0 (360 ms)
 *  480ms   sema follows the gesture toward Applications (420 ms)
 *  900ms   destination acknowledges the gesture, ghost fades (180 ms)
 * 1080ms   return to the static composition; Replay remains available
 *
 * Replay captures the visible frame before replacing any running animation.
 * Reduced motion: static composition and instructions, with no travel animation.
 */
const TIMING = { drawFil: 120, moveApp: 480, acknowledge: 900, finish: 1080 };
const FIL = { duration: 360, easing: "cubic-bezier(.22,.8,.24,1)" };
const GESTURE = { duration: 420, lift: 8, damping: 7, shadow: 0.28, frames: 28 };
const ACKNOWLEDGEMENT = { duration: 180, brightness: 1.18 };
const REPLAY = { resetDuration: 120 };
const COPY = { resetDelay: 2200 };

const demo = document.querySelector("#install-demo");
const path = document.querySelector("#install-fil-path");
const app = document.querySelector("#demo-app");
const applications = document.querySelector("#demo-applications");
const ghost = document.querySelector("#drag-ghost");
const replay = document.querySelector("#replay");
const preference = matchMedia("(prefers-reduced-motion: reduce)");
const tuning = { speed: 1, reduce: false };
const localPreview = ["localhost", "127.0.0.1", "[::1]"].includes(location.hostname);
let stage = 0;
let timers = [];
let animations = [];
let generation = 0;
let copyTimer = 0;

function setStage(next) {
  stage = next;
  demo.dataset.stage = String(stage);
}

function stopSequence() {
  generation += 1;
  timers.forEach(clearTimeout);
  timers = [];
  animations.forEach((animation) => animation.cancel());
  animations = [];
}

function animate(element, frames, options) {
  if (!element.animate) return null;
  const animation = element.animate(frames, { fill: "forwards", ...options });
  animations.push(animation);
  return animation;
}

function finalComposition() {
  stopSequence();
  path.style.strokeDasharray = "none";
  path.style.strokeDashoffset = "0";
  ghost.style.opacity = "0";
  ghost.style.transform = "none";
  applications.style.filter = "none";
  setStage(4);
}

function gestureFrames(distance) {
  const settled = 1 - Math.exp(-GESTURE.damping) * (1 + GESTURE.damping);
  return Array.from({ length: GESTURE.frames + 1 }, (_, index) => {
    const time = index / GESTURE.frames;
    const progress = (1 - Math.exp(-GESTURE.damping * time) * (1 + GESTURE.damping * time)) / settled;
    return { transform: `translate(${distance * progress}px, ${-Math.sin(Math.PI * progress) * GESTURE.lift}px)`,
      opacity: index === 0 ? 0 : 0.96, offset: time };
  });
}

function play() {
  const visible = { transform: getComputedStyle(ghost).transform, opacity: getComputedStyle(ghost).opacity,
    dashOffset: getComputedStyle(path).strokeDashoffset, destinationFilter: getComputedStyle(applications).filter };
  const interrupted = animations.some((animation) => animation.playState === "running");
  stopSequence();
  if (preference.matches || tuning.reduce || !ghost.animate) {
    finalComposition();
    return;
  }
  const currentGeneration = generation;
  const delay = interrupted ? REPLAY.resetDuration / tuning.speed : 0;
  path.style.strokeDasharray = "1";
  path.style.strokeDashoffset = "1";
  ghost.style.opacity = "0";
  ghost.style.transform = "none";
  setStage(0);
  if (interrupted) {
    animate(ghost, [{ transform: visible.transform, opacity: visible.opacity }, { transform: "none", opacity: 0 }], { duration: delay, easing: "ease-out" });
    animate(path, [{ strokeDashoffset: visible.dashOffset }, { strokeDashoffset: 1 }], { duration: delay });
    animate(applications, [{ filter: visible.destinationFilter }, { filter: "none" }], { duration: delay });
  }
  const schedule = (at, action) => {
    timers.push(setTimeout(() => { if (generation === currentGeneration) action(); }, delay + at / tuning.speed));
  };
  schedule(TIMING.drawFil, () => {
    setStage(1);
    animate(path, [{ strokeDashoffset: 1 }, { strokeDashoffset: 0 }], { duration: FIL.duration / tuning.speed, easing: FIL.easing });
  });
  schedule(TIMING.moveApp, () => {
    setStage(2);
    const distance = applications.getBoundingClientRect().left - app.getBoundingClientRect().left;
    animate(ghost, gestureFrames(distance), { duration: GESTURE.duration / tuning.speed, easing: "linear" });
  });
  schedule(TIMING.acknowledge, () => {
    setStage(3);
    const transform = getComputedStyle(ghost).transform;
    animate(ghost, [{ transform, opacity: 0.96 }, { transform, opacity: 0 }], { duration: ACKNOWLEDGEMENT.duration / tuning.speed });
    animate(applications, [{ filter: "brightness(1)" }, { filter: `brightness(${ACKNOWLEDGEMENT.brightness})`, offset: 0.3 }, { filter: "brightness(1)" }], { duration: ACKNOWLEDGEMENT.duration / tuning.speed });
  });
  schedule(TIMING.finish, () => {
    setStage(4);
    // Completed animations are cancelled after their endpoint is committed to CSS.
    path.style.strokeDasharray = "none";
    path.style.strokeDashoffset = "0";
    ghost.style.opacity = "0";
    ghost.style.transform = "none";
    animations.forEach((animation) => animation.cancel());
    animations = [];
    timers = [];
  });
}

replay.hidden = preference.matches;
replay.addEventListener("click", (event) => {
  if (event.altKey && localPreview) document.querySelector("#motion-tuning").hidden = !document.querySelector("#motion-tuning").hidden;
  play();
});
preference.addEventListener("change", () => { replay.hidden = preference.matches; finalComposition(); });
addEventListener("resize", finalComposition);
document.addEventListener("visibilitychange", () => { if (document.hidden) finalComposition(); });
addEventListener("pagehide", () => { stopSequence(); clearTimeout(copyTimer); });
if ("IntersectionObserver" in window) {
  const observer = new IntersectionObserver((entries) => {
    if (entries.some((entry) => entry.isIntersecting)) { play(); observer.disconnect(); }
  }, { threshold: 0.4 });
  observer.observe(demo);
} else finalComposition();

document.querySelectorAll("[data-download]").forEach((link) => {
  link.addEventListener("click", () => {
    document.querySelector("#download-status").textContent = "Le navigateur prend en charge le téléchargement. Retrouvez le fichier dans vos téléchargements.";
  });
});
const copyButton = document.querySelector("#copy-homebrew");
if (copyButton && navigator.clipboard?.writeText) {
  copyButton.hidden = false;
  copyButton.addEventListener("click", async () => {
    clearTimeout(copyTimer);
    try {
      await navigator.clipboard.writeText(document.querySelector("#homebrew-command").textContent);
      copyButton.textContent = "Copié";
      document.querySelector("#homebrew-copy-status").textContent = "Commande copiée.";
    } catch {
      copyButton.textContent = "Sélectionner";
      const selection = getSelection();
      const range = document.createRange();
      range.selectNodeContents(document.querySelector("#homebrew-command"));
      selection.removeAllRanges(); selection.addRange(range);
      document.querySelector("#homebrew-copy-status").textContent = "Copie indisponible. La commande est sélectionnée pour une copie manuelle.";
    }
    copyTimer = setTimeout(() => { copyButton.textContent = "Copier"; }, COPY.resetDelay);
  });
}

if (localPreview) {
  const tuningInputs = [
    { id: "motion-speed", apply: (value) => { tuning.speed = value; }, format: (value) => `${value}×` },
    { id: "motion-shadow", apply: (value) => { GESTURE.shadow = value; demo.querySelector(".demo-volume").style.setProperty("--drag-shadow", value); }, format: (value) => String(value).replace(".", ",") },
    { id: "motion-damping", apply: (value) => { GESTURE.damping = value; }, format: (value) => String(value) },
    { id: "motion-lift", apply: (value) => { GESTURE.lift = value; }, format: (value) => `${value} px` }
  ];
  tuningInputs.forEach(({ id, apply, format }) => {
    const input = document.getElementById(id);
    input.addEventListener("input", () => {
      const value = Number(input.value);
      apply(value);
      input.nextElementSibling.textContent = format(value);
      play();
    });
  });
  document.querySelector("#motion-reduce").addEventListener("change", (event) => { tuning.reduce = event.target.checked; play(); });
} else {
  document.querySelector("#motion-tuning").remove();
}
