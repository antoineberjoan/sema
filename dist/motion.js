"use strict";

/* ANIMATION STORYBOARD — scroll controls progress, not elapsed time.
 *
 *  0%   visual enters the viewport, slightly lowered and softened
 *  →    visual settles while the visitor scrolls
 *  →    the sentence reveals word by word, from 88% to 38% of the viewport
 * 100%  keep everything visible, including when scrolling back up
 *
 * Reduced motion or no JavaScript: all content is immediately visible.
 */
const SCROLL_MOTION = {
  product: { start: 1, end: 0.55, offset: 28, scale: 0.99, opacity: 0.72 },
  search:  { start: 0.9, end: 0.52, offset: 18, scale: 1, opacity: 0.6 },
  text:    { start: 0.88, end: 0.38, opacity: 0.28, wordStagger: 0.65 }
};

const motionPreference = matchMedia("(prefers-reduced-motion: reduce)");
const motionStages = [];
const clampProgress = (value) => Math.min(1, Math.max(0, value));
let motionFrame = 0;

document.querySelectorAll("[data-scroll-visual]").forEach((element) => {
  motionStages.push({ element, config: SCROLL_MOTION[element.dataset.scrollVisual], progress: 0 });
});

document.querySelectorAll("[data-scroll-text]").forEach((element) => {
  // Keep one uninterrupted sentence for assistive technology.
  const readable = document.createElement("span");
  readable.className = "sr-only";
  readable.textContent = element.textContent;
  const visual = document.createElement("span");
  visual.setAttribute("aria-hidden", "true");
  visual.append(...element.childNodes);
  const walker = document.createTreeWalker(visual, NodeFilter.SHOW_TEXT);
  const nodes = [];
  while (walker.nextNode()) nodes.push(walker.currentNode);
  const words = [];
  nodes.forEach((node) => {
    const fragment = document.createDocumentFragment();
    node.textContent.split(/(\s+)/).filter(Boolean).forEach((part) => {
      if (/^\s+$/.test(part)) fragment.append(document.createTextNode(part));
      else {
        const word = document.createElement("span");
        word.className = "scroll-word";
        word.textContent = part;
        words.push(word);
        fragment.append(word);
      }
    });
    node.replaceWith(fragment);
  });
  element.append(readable, visual);
  motionStages.push({ element, config: SCROLL_MOTION.text, words, progress: 0 });
});

function renderMotion() {
  motionFrame = 0;
  const viewportHeight = document.documentElement.clientHeight;
  // Read layout before writing styles, and stop measuring completed reveals.
  const frames = motionStages.map((stage) => {
    if (motionPreference.matches || stage.progress === 1) return { stage, progress: 1 };
    const top = stage.element.getBoundingClientRect().top;
    const progress = clampProgress((viewportHeight * stage.config.start - top) / (viewportHeight * (stage.config.start - stage.config.end)));
    return { stage, progress: Math.max(stage.progress, progress) };
  });
  frames.forEach(({stage, progress}) => {
    stage.progress = progress;
    const config = stage.config;
    if (stage.words) {
      stage.words.forEach((word, index) => {
        const stagger = (index / Math.max(1, stage.words.length - 1)) * config.wordStagger;
        const wordProgress = clampProgress((progress - stagger) / (1 - config.wordStagger));
        word.style.setProperty("--word-opacity", String(config.opacity + wordProgress * (1 - config.opacity)));
      });
    } else {
      stage.element.style.setProperty("--visual-opacity", String(config.opacity + progress * (1 - config.opacity)));
      stage.element.style.setProperty("--visual-offset", `${config.offset * (1 - progress)}px`);
      stage.element.style.setProperty("--visual-scale", String(config.scale + progress * (1 - config.scale)));
    }
  });
}

function scheduleMotion() {
  if (!motionFrame) motionFrame = requestAnimationFrame(renderMotion);
}

addEventListener("scroll", scheduleMotion, { passive: true });
addEventListener("resize", scheduleMotion);
motionPreference.addEventListener("change", scheduleMotion);
renderMotion();
