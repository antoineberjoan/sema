/* Partage le téléchargement principal et son apparition dans le header. */
const header = document.querySelector('.marketing-header');
const headerDownload = header?.querySelector('[data-header-download]');
const primaryDownload = document.querySelector('.hero [data-download], .release-action [data-download]');

if (header && headerDownload && primaryDownload && 'IntersectionObserver' in window) {
  // La destination vient du bouton principal : une seule URL à maintenir par page.
  headerDownload.href = primaryDownload.href;
  if (primaryDownload.hasAttribute('download')) {
    headerDownload.setAttribute('download', primaryDownload.getAttribute('download'));
  }

  let observer;
  let headerHeight = 0;
  const updateObserver = () => {
    const height = header.offsetHeight;
    if (height === headerHeight) return;
    headerHeight = height;
    observer?.disconnect();
    observer = new IntersectionObserver(([entry]) => {
      // En dessous de la vue au chargement : aucun bouton prématuré.
      const visible = !entry.isIntersecting && entry.boundingClientRect.bottom <= headerHeight;
      header.classList.toggle('has-download', visible);
      headerDownload.toggleAttribute('inert', !visible);
      headerDownload.setAttribute('aria-hidden', String(!visible));
    }, { rootMargin: `-${headerHeight}px 0px 0px 0px` });
    observer.observe(primaryDownload);
  };
  updateObserver();
  window.addEventListener('resize', updateObserver);
}
