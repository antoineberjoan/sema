/* Copie la commande Homebrew et déclenche chaque scène animée de la landing à son entrée dans l’écran ; la scène recherche se rejoue tant qu’elle est visible. */
(() => {
  const COPY = { feedbackDuration: 2200 };
  const button = document.querySelector('[data-copy-homebrew]');
  const command = document.querySelector('#homebrew-command');
  const status = document.querySelector('#homebrew-copy-status');
  let resetTimer;
  if (button && command && status) {
    button.disabled = false;
    button.addEventListener('click', async () => {
      clearTimeout(resetTimer);
      button.removeAttribute('data-copied');
      try {
        if (!navigator.clipboard?.writeText) throw new Error('clipboard unavailable');
        await navigator.clipboard.writeText(command.textContent);
        button.dataset.copied = 'true';
        status.textContent = 'commande copiée.';
        resetTimer = setTimeout(() => {
          button.removeAttribute('data-copied'); status.textContent = '';
        }, COPY.feedbackDuration);
      } catch {
        const range = document.createRange(); range.selectNodeContents(command);
        const selection = getSelection(); selection.removeAllRanges(); selection.addRange(range);
        status.textContent = 'la commande est sélectionnée. copiez-la avec commande C.';
      }
    });
  }
  addEventListener('pagehide', () => clearTimeout(resetTimer));

  // Chaque scène part de son état caché puis joue quand 35 % de sa hauteur est visible. Une scène « data-loop » se rejoue après une pause, tant qu’elle reste visible. Sans script ou avec « réduire les animations », elle s’affiche déjà terminée.
  const scenes = document.querySelectorAll('[data-scene]');
  if (matchMedia('(prefers-reduced-motion: reduce)').matches || !('IntersectionObserver' in window)) return;
  const timers = new Map();
  const duration = (name) => parseFloat(getComputedStyle(document.documentElement).getPropertyValue(name));
  const play = (scene) => {
    scene.removeAttribute('data-rewind');
    scene.dataset.play = '';
    if (!('loop' in scene.dataset)) return;
    timers.set(scene, setTimeout(() => {
      scene.dataset.rewind = '';
      timers.set(scene, setTimeout(() => {
        delete scene.dataset.play;
        void scene.offsetWidth;
        play(scene);
      }, duration('--scene-enter')));
    }, duration('--scene-loop')));
  };
  const observer = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      const scene = entry.target;
      if (entry.isIntersecting) {
        if (!('play' in scene.dataset)) play(scene);
        continue;
      }
      if (!('loop' in scene.dataset)) continue;
      clearTimeout(timers.get(scene));
      scene.removeAttribute('data-play'); scene.removeAttribute('data-rewind');
    }
    for (const entry of entries) if (entry.isIntersecting && !('loop' in entry.target.dataset)) observer.unobserve(entry.target);
  }, { threshold: .35 });
  for (const scene of scenes) {
    scene.dataset.armed = '';
    observer.observe(scene);
  }
  addEventListener('pagehide', () => timers.forEach(clearTimeout));
})();
