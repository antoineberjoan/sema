/* Anime les aperçus locaux de la landing ; aucune requête ni préférence utilisateur. */
(() => {
  /* STORYBOARD — une entrée par scène, aucune boucle automatique.
   *    0 ms  la scène choisie est immédiatement utilisable
   *  360 ms  la recherche apparaît / le hub reprend le premier plan
   *  700 ms  les cartes terminent leur arrivée (décalage de 75 ms)
   * 1100 ms  le tracé de l’historique est complet
   * Hors écran, onglet masqué ou mouvement réduit : état final au repos.
   * Les durées d’entrée sont centralisées dans .product-demo (landing.css).
   */
  const demo = document.querySelector('.product-demo');
  if (!demo) return;
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const tabs = [...document.querySelectorAll('[data-demo-scene]')];
  const command = demo.querySelector('.demo-command');
  const input = command.querySelector('input');
  const results = command.querySelector('.command-results');
  const chart = demo.querySelector('.focus-chart');
  const chartPath = chart.querySelector('path');
  const description = document.querySelector('[data-demo-description]');
  const SCENES = {
    glance: 'vos favoris, réunis dans un bandeau de verre.',
    search: 'un raccourci. le repère que vous cherchez.',
    history: 'changez de période. retrouvez la perspective.',
  };
  // Courbes illustratives indépendantes, sans données de marché ni calcul financier.
  const SERIES = {
    euro: { name: 'euro / dollar', value: '1,1642', unit: 'USD', points: [32,30,34,31,38,36,40,37,46,42,49,45,52,50,59,55,61,57,68,63,70,67,74,71,79,75,82,78,87,84,91] },
    bce: { name: 'taux de dépôt BCE', value: '2,00', unit: '%', points: [82,82,82,82,82,73,73,73,73,63,63,63,63,53,53,53,53,43,43,43,43,33,33,33,23,23,23,23,23,23,23] },
    livret: { name: 'livret A', value: '1,70', unit: '%', points: [72,72,72,72,72,72,72,72,72,72,72,72,72,72,72,72,46,46,46,46,46,46,46,46,46,46,46,46,46,46,46] },
  };
  const PERIODS = { '3m': { count: 8, start: 'juil. 2026' }, '6m': { count: 16, start: 'avr. 2026' }, '1y': { count: 31, start: 'oct. 2025' } };
  let selectedSeries = 'euro';
  let selectedPeriod = '1y';
  let matching = Object.keys(SERIES);
  let selectedResult = 0;
  const controls = document.querySelector('.demo-controls');
  controls.hidden = false;
  demo.querySelector('.demo-window').inert = true;
  const setStage = () => { demo.dataset.stage = reducedMotion.matches ? '0' : '1'; };
  const showScene = (scene, focusSearch = false) => {
    demo.dataset.stage = '0';
    demo.dataset.scene = scene;
    demo.setAttribute('aria-labelledby', `demo-${scene}`);
    tabs.forEach(tab => {
      const selected = tab.dataset.demoScene === scene;
      tab.setAttribute('aria-selected', String(selected));
      tab.tabIndex = selected ? 0 : -1;
    });
    command.hidden = scene !== 'search';
    demo.querySelector('.demo-window').inert = scene !== 'history';
    demo.querySelector('.demo-ribbon').inert = scene !== 'glance';
    description.textContent = SCENES[scene];
    setStage();
    if (focusSearch) input.focus({ preventScroll: true });
  };
  const drawHistory = () => {
    const series = SERIES[selectedSeries];
    demo.querySelector('[data-focus-name]').textContent = series.name;
    demo.querySelector('[data-focus-value]').textContent = series.value;
    demo.querySelector('[data-focus-unit]').textContent = series.unit;
    const period = PERIODS[selectedPeriod];
    const points = series.points.slice(-period.count);
    chartPath.setAttribute('d', points.map((value, index) => `${index ? 'L' : 'M'}${(index / (points.length - 1) * 600).toFixed(1)} ${(180 - value * 1.7).toFixed(1)}`).join(' '));
    chartPath.setAttribute('pathLength', '1');
    chart.setAttribute('aria-label', `historique fictif ${series.name}, ${period.start} à octobre 2026`);
    demo.querySelector('[data-chart-start]').textContent = period.start;
    demo.querySelectorAll('[data-open-series]').forEach(button => {
      const selected = button.dataset.openSeries === selectedSeries;
      button.classList.toggle('is-selected', selected);
      if (button.closest('.focus-switcher')) button.setAttribute('aria-pressed', String(selected));
    });
    demo.querySelectorAll('[data-period]').forEach(button => {
      const selected = button.dataset.period === selectedPeriod;
      button.classList.toggle('is-selected', selected);
      button.setAttribute('aria-pressed', String(selected));
    });
  };
  const openSeries = key => {
    selectedSeries = key;
    drawHistory();
    const wasSearch = demo.dataset.scene === 'search';
    showScene('history');
    if (wasSearch) tabs[2].focus({ preventScroll: true });
  };
  demo.querySelectorAll('[data-open-series]').forEach(button => button.addEventListener('click', () => openSeries(button.dataset.openSeries)));
  demo.querySelectorAll('[data-period]').forEach(button => button.addEventListener('click', () => {
    selectedPeriod = button.dataset.period;
    drawHistory();
  }));
  const renderResults = () => {
    results.replaceChildren();
    matching.forEach((key, index) => {
      const series = SERIES[key];
      const button = document.createElement('button');
      button.className = `command-result${index === selectedResult ? ' is-selected' : ''}`;
      button.type = 'button';
      const name = document.createElement('span');
      name.textContent = series.name;
      const value = document.createElement('small');
      value.textContent = `${series.value} ${series.unit}`;
      button.append(name, value);
      button.addEventListener('click', () => openSeries(key));
      results.append(button);
    });
    if (!matching.length) {
      const empty = document.createElement('p');
      empty.className = 'command-empty';
      empty.textContent = 'essayez « euro », « BCE » ou « livret ».';
      results.append(empty);
    }
  };
  input.addEventListener('input', () => {
    const query = input.value.trim().toLocaleLowerCase('fr').normalize('NFD').replace(/[\u0300-\u036f]/g, '');
    matching = Object.keys(SERIES).filter(key => SERIES[key].name.toLocaleLowerCase('fr').normalize('NFD').replace(/[\u0300-\u036f]/g, '').includes(query));
    selectedResult = 0;
    renderResults();
  });
  input.addEventListener('keydown', event => {
    if (['ArrowDown', 'ArrowUp'].includes(event.key) && matching.length) {
      event.preventDefault();
      selectedResult = (selectedResult + (event.key === 'ArrowDown' ? 1 : -1) + matching.length) % matching.length;
      renderResults();
    } else if (event.key === 'Enter' && matching.length) {
      event.preventDefault();
      openSeries(matching[selectedResult]);
    } else if (event.key === 'Escape') {
      showScene('history');
      tabs[2].focus({ preventScroll: true });
    }
  });
  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => showScene(tab.dataset.demoScene));
    tab.addEventListener('keydown', event => {
      let next = index;
      if (event.key === 'ArrowRight') next = (index + 1) % tabs.length;
      else if (event.key === 'ArrowLeft') next = (index - 1 + tabs.length) % tabs.length;
      else if (event.key === 'Home') next = 0;
      else if (event.key === 'End') next = tabs.length - 1;
      else return;
      event.preventDefault();
      tabs[next].focus();
      showScene(tabs[next].dataset.demoScene);
    });
  });
  demo.querySelector('[data-search-trigger]').addEventListener('click', () => showScene('search', true));
  // Le raccourci reste limité à l’aperçu : aucune interception globale du navigateur.
  demo.addEventListener('keydown', event => {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
      event.preventDefault();
      showScene('search', true);
    }
  });
  if ('IntersectionObserver' in window) {
    let hasEntered = false;
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && !hasEntered) {
        hasEntered = true;
        setStage();
      } else if (!entry.isIntersecting) {
        demo.dataset.stage = '0';
      }
    }, { threshold: .3 });
    observer.observe(demo);
  }
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) demo.dataset.stage = '0';
  });
  reducedMotion.addEventListener('change', () => { demo.dataset.stage = '0'; });
  drawHistory();
  renderResults();
})();
