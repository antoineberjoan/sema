/* Orchestre trois mises en scène distinctes, jouées une fois puis laissées au repos. */
(() => {
  /* STORYBOARD — temps relatifs à l’arrivée de chaque scène dans l’écran.
   * Bandeau : cartes 0→650 ms, décalées de 95 ms ; courbes à 320 ms pendant 1100 ms.
   * Recherche : surface 0→650 ms ; touches à 100 ms ; saisie à 430 ms ; résultats à 850 ms.
   * Historique : tracé 0→1800 ms, aire à 200 ms ; point et variation à 1580 ms.
   * Une seule observation par scène. Masquage ou réduction des animations : état final, annulation.
   */
  const features = [...document.querySelectorAll('.landing [data-scene]')];
  if (!features.length) return;
  const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const TIMING = {
    enter: 650, cardStep: 95, cardTrace: 320, miniTrace: 1100,
    keyPress: 100, keyDuration: 360, query: 430, typing: 500,
    results: 850, resultStep: 90, resultEnter: 450,
    historyTrace: 1800, area: 200, historyEnd: 1580, endEnter: 450,
  };
  const EASING = 'cubic-bezier(.22, 1, .36, 1)';
  const ENTER = [{ opacity: 0, transform: 'translateY(24px)' }, { opacity: 1, transform: 'none' }];
  const FADE = [{ opacity: 0 }, { opacity: 1 }];
  const TRACE = [{ strokeDasharray: '1', strokeDashoffset: '1' }, { strokeDasharray: '1', strokeDashoffset: '0' }];
  const animations = new Set();
  let observer;

  function animate(element, frames, duration, delay = 0, easing = EASING) {
    const animation = element.animate(frames, { duration, delay, easing, fill: 'both' });
    animations.add(animation);
    animation.onfinish = () => { animation.cancel(); animations.delete(animation); };
  }

  function play(feature) {
    feature.dataset.stage = '1';
    const all = selector => [...feature.querySelectorAll(selector)];
    switch (feature.dataset.scene) {
      case 'glance':
        all('.glance-card').forEach((card, index) => animate(card, ENTER, TIMING.enter, index * TIMING.cardStep));
        all('.mini-chart path').forEach(path => animate(path, TRACE, TIMING.miniTrace, TIMING.cardTrace));
        break;
      case 'search':
        all('.command-surface').forEach(surface => animate(surface, ENTER, TIMING.enter));
        all('.keycap').forEach(key => animate(key,
          [{ translate: '0 0' }, { translate: '0 3px', offset: .4 }, { translate: '0 0' }], TIMING.keyDuration, TIMING.keyPress));
        all('.command-query').forEach(query => animate(query,
          [{ clipPath: 'inset(0 100% 0 0)' }, { clipPath: 'inset(0 0% 0 0)' }], TIMING.typing, TIMING.query, 'steps(4, end)'));
        all('.command-result').forEach((result, index) => animate(result, ENTER, TIMING.resultEnter, TIMING.results + index * TIMING.resultStep));
        break;
      case 'history':
        all('.history-stroke').forEach(path => animate(path, TRACE, TIMING.historyTrace));
        all('.history-area').forEach(area => animate(area,
          [{ clipPath: 'inset(0 100% 0 0)' }, { clipPath: 'inset(0 0% 0 0)' }], TIMING.historyTrace, TIMING.area));
        all('.history-point, .history-change').forEach(element => animate(element, FADE, TIMING.endEnter, TIMING.historyEnd));
        break;
    }
  }

  function finish() {
    observer?.disconnect();
    features.forEach(feature => { feature.dataset.stage = '2'; });
    animations.forEach(animation => animation.cancel());
    animations.clear();
  }

  if (motion.matches || document.hidden || !('IntersectionObserver' in window) || !Element.prototype.animate) {
    finish();
    return;
  }
  observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      play(entry.target.closest('[data-scene]'));
      observer.unobserve(entry.target);
    });
  }, { threshold: .18 });
  features.forEach(feature => {
    feature.dataset.stage = '0';
    observer.observe(feature.querySelector('figure'));
  });
  motion.addEventListener('change', () => { if (motion.matches) finish(); });
  document.addEventListener('visibilitychange', () => { if (document.hidden) finish(); });
  window.addEventListener('pagehide', finish);
})();
