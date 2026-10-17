/* Relie les scènes produit au défilement natif, sans interaction ni boucle autonome. */
(() => {
  const section = document.querySelector('.landing .product');
  if (!section) return;

  /* STORYBOARD — progression de la section, réversible au défilement.
   * 0–24 %   : quatre favoris dans leur bandeau de verre.
   * 24–36 %  : le bandeau se retire, la recherche apparaît.
   * 36–60 %  : « euro » se compose et les résultats restent lisibles.
   * 60–74 %  : la recherche cède la place au hub Focus.
   * 74–96 %  : la courbe se dessine, puis le dernier état reste visible.
   * Sans mouvement, sans JS ou en fenêtre basse : trois vues dans le flux.
   */
  const STORY = {
    search: [0.24, 0.36],
    query: [0.36, 0.5],
    focus: [0.6, 0.74],
    trace: [0.74, 0.96],
    minimumHeight: 580,
    windowDistance: 18,
    windowBlur: 8,
    windowScale: 0.97,
    searchDistance: 16,
    searchScale: 0.98,
    copyDistance: 6,
    ribbonDistance: -18,
    cardDistance: 4,
    queryText: 'euro'
  };
  const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const sticky = section.querySelector('.story-sticky');
  const illustration = section.querySelector('.product-demo');
  const query = section.querySelector('[data-search-text]');
  const copies = [...section.querySelectorAll('[data-story-copy]')];
  let frame = null;
  let enabled = false;

  const clamp = value => Math.max(0, Math.min(1, value));
  const smooth = (range, progress) => {
    const value = clamp((progress - range[0]) / (range[1] - range[0]));
    return value * value * (3 - 2 * value);
  };
  const set = (name, value) => section.style.setProperty(`--${name}`, value);

  function render() {
    frame = null;
    if (!enabled || document.hidden) return;
    const top = parseFloat(getComputedStyle(sticky).top);
    const travel = section.offsetHeight - sticky.offsetHeight;
    const progress = clamp((top - section.getBoundingClientRect().top) / Math.max(1, travel));
    const search = smooth(STORY.search, progress);
    const focus = smooth(STORY.focus, progress);
    const command = search * (1 - focus);
    set('ribbon-opacity', 1 - search);
    set('ribbon-y', `${search * STORY.ribbonDistance}px`);
    set('card-step', `${search * STORY.cardDistance}px`);
    set('command-opacity', command);
    set('command-y', `${(1 - search - focus) * STORY.searchDistance}px`);
    set('command-scale', STORY.searchScale + command * (1 - STORY.searchScale));
    set('window-opacity', 0.1 + search * 0.18 + focus * 0.72);
    set('window-blur', `${(1 - focus) * (STORY.windowBlur - search * 5)}px`);
    set('window-y', `${(1 - focus) * STORY.windowDistance}px`);
    set('window-scale', STORY.windowScale + focus * (1 - STORY.windowScale));
    set('chart-offset', 1 - smooth(STORY.trace, progress));
    const opacities = [1 - search, command, focus];
    copies.forEach((copy, index) => {
      copy.style.setProperty('--copy-opacity', opacities[index]);
      copy.style.setProperty('--copy-y', `${(1 - opacities[index]) * STORY.copyDistance}px`);
    });
    const letters = Math.ceil(smooth(STORY.query, progress) * STORY.queryText.length);
    query.textContent = STORY.queryText.slice(0, letters);
    illustration.dataset.scene = focus > 0.5 ? 'history' : search > 0.5 ? 'search' : 'glance';
  }

  function schedule() {
    if (enabled && !document.hidden && frame === null) frame = requestAnimationFrame(render);
  }

  function configure() {
    enabled = !motion.matches && window.innerHeight >= STORY.minimumHeight;
    section.classList.toggle('is-scroll-story', enabled);
    if (!enabled) {
      if (frame !== null) cancelAnimationFrame(frame);
      frame = null;
      query.textContent = STORY.queryText;
    }
    schedule();
  }

  window.addEventListener('scroll', schedule, { passive: true });
  window.addEventListener('resize', configure, { passive: true });
  window.addEventListener('pageshow', configure);
  motion.addEventListener('change', configure);
  document.addEventListener('visibilitychange', () => {
    if (document.hidden && frame !== null) {
      cancelAnimationFrame(frame);
      frame = null;
    } else schedule();
  });
  configure();
})();
