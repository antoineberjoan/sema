/* Révèle chaque fonctionnalité à son arrivée, sans modifier le défilement de la page. */
(() => {
  /* STORYBOARD — une entrée par section, aucune scène partagée.
   *    0 ms : le visuel apparaît en remontant légèrement.
   *  240 ms : les courbes se tracent ou les résultats de recherche apparaissent.
   * 1540 ms : tout reste au repos, sans répétition au retour.
   * Durées et décalages sont centralisés dans .landing .product (landing.css).
   * Réduire les animations ou masquer l’onglet donne immédiatement l’état final.
   */
  const features = [...document.querySelectorAll('.landing .feature')];
  if (!features.length) return;
  const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const REVEAL = { rootMargin: '0px 0px 48px 0px', threshold: 0 };
  let observer;

  function finish() {
    observer?.disconnect();
    features.forEach(feature => { feature.dataset.stage = '2'; });
  }

  if (motion.matches || document.hidden || !('IntersectionObserver' in window)) {
    finish();
    return;
  }

  observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      entry.target.closest('.feature').dataset.stage = '1';
      observer.unobserve(entry.target);
    });
  }, REVEAL);
  features.forEach(feature => {
    feature.dataset.stage = '0';
    observer.observe(feature.querySelector('.product-demo'));
  });
  motion.addEventListener('change', () => { if (motion.matches) finish(); });
  document.addEventListener('visibilitychange', () => { if (document.hidden) finish(); });
})();
