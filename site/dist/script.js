const commandLink = document.querySelector('[data-copy-command]');
const copyStatus = document.getElementById('copy-status');
const COPY_FEEDBACK_MS = 1800;
let feedbackTimer;

if (commandLink && navigator.clipboard?.writeText) {
  commandLink.addEventListener('click', async (event) => {
    event.preventDefault();
    const command = commandLink.dataset.copyCommand;
    try {
      await navigator.clipboard.writeText(command);
      clearTimeout(feedbackTimer);
      commandLink.textContent = 'commande copiée';
      copyStatus.textContent = 'commande homebrew copiée dans le presse-papiers.';
      feedbackTimer = setTimeout(() => { commandLink.textContent = command; }, COPY_FEEDBACK_MS);
    } catch {
      window.location.assign(commandLink.href);
    }
  });
}
