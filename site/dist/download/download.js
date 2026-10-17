"use strict";
/* Ouvre l’aide ciblée et permet de copier la commande Homebrew, sans simuler d’installation. */
(() => {
  const COPY = { resetDelay: 2200 };
  let copyTimer;
  document.querySelectorAll('[data-download]').forEach(link => {
    link.addEventListener('click', () => {
      document.querySelector('#download-status').textContent = 'le navigateur prend en charge le téléchargement. retrouvez le fichier dans vos téléchargements.';
    });
  });

  const copyButton = document.querySelector('#copy-homebrew');
  if (copyButton && navigator.clipboard?.writeText) {
    copyButton.hidden = false;
    copyButton.addEventListener('click', async () => {
      clearTimeout(copyTimer);
      try {
        await navigator.clipboard.writeText(document.querySelector('#homebrew-command').textContent);
        copyButton.textContent = 'copié';
        document.querySelector('#homebrew-copy-status').textContent = 'commande copiée.';
      } catch {
        const range = document.createRange();
        range.selectNodeContents(document.querySelector('#homebrew-command'));
        const selection = getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        document.querySelector('#homebrew-copy-status').textContent = 'la commande est sélectionnée pour une copie manuelle.';
      }
      copyTimer = setTimeout(() => { copyButton.textContent = 'copier'; }, COPY.resetDelay);
    });
  }
  addEventListener('pagehide', () => clearTimeout(copyTimer));

  function revealHelp() {
    const target = document.getElementById(location.hash.slice(1));
    if (target?.tagName === 'DETAILS') target.open = true;
  }
  revealHelp();
  addEventListener('hashchange', revealHelp);
})();
