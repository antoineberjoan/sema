/* Copie la commande Homebrew et lance une seule fois la démonstration visible, avec arrêt explicite. */
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

  const video = document.querySelector('[data-demo-video]');
  if (!video) return;
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  let played = false;
  let observer;
  const stop = () => { video.pause(); observer?.disconnect(); };
  video.addEventListener('play', () => { played = true; });
  if (!reduced.matches && 'IntersectionObserver' in window) {
    observer = new IntersectionObserver(([entry]) => {
      if (!entry.isIntersecting || entry.intersectionRatio < .35) { video.pause(); return; }
      if (played || document.hidden || reduced.matches) return;
      played = true;
      video.play().catch(() => { /* Les contrôles natifs restent disponibles si la lecture automatique est refusée. */ });
    }, { threshold: .35 });
    observer.observe(video);
  }
  reduced.addEventListener('change', () => { if (reduced.matches) stop(); });
  document.addEventListener('visibilitychange', () => { if (document.hidden) video.pause(); });
  addEventListener('pagehide', stop);
})();
