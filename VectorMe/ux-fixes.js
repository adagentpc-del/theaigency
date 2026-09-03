(() => {
  'use strict';
  const authTitle = document.getElementById('authTitle');
  const authSubmit = document.getElementById('authSubmit');
  const authToggle = document.getElementById('authToggle');
  const authDialog = document.getElementById('accountDialog');
  const authError = document.getElementById('authError');
  const printCheck = document.getElementById('printCheck');
  const downloadAll = document.getElementById('downloadAll');
  const useCases = document.getElementById('useCases');
  const exportButtons = ['downloadSvg','downloadPdf','downloadPng','downloadAll'].map(id => document.getElementById(id)).filter(Boolean);
  let exportIntent = false;

  function syncAuthCopy() {
    if (!authTitle || !authSubmit || authSubmit.classList.contains('hidden')) return;
    const creating = /create/i.test(authTitle.textContent || '');
    authSubmit.textContent = creating ? 'Create account' : 'Sign in';
    if (authToggle) authToggle.textContent = creating ? 'Already have an account? Sign in' : 'Create an account instead';
  }

  function recommendationFor(useCase) {
    if (/embroidery/i.test(useCase)) return {
      title: 'Next step: send the SVG or Vector PDF to your embroidery digitizer.',
      detail: 'Ask the digitizer to create the DST, PES, or other machine file required by your embroidery shop.'
    };
    if (/web|digital/i.test(useCase)) return {
      title: 'Best file for digital use: SVG.',
      detail: 'Use the transparent PNG only when a website or platform cannot accept SVG.'
    };
    if (/vinyl|decal/i.test(useCase)) return {
      title: 'Best files to send your vinyl or decal shop: SVG or Vector PDF.',
      detail: 'The SVG is especially useful for cut-path workflows. Review any small-shape warnings before production.'
    };
    return {
      title: 'Best files to send your printer: SVG or Vector PDF.',
      detail: 'If your vendor asks for AI or EPS, send them the SVG/PDF first and ask whether they can open or convert the vector file.'
    };
  }

  function syncNextStep() {
    if (!printCheck || printCheck.classList.contains('hidden')) return;
    let box = document.getElementById('vendorNextStep');
    if (!box) {
      box = document.createElement('section');
      box.id = 'vendorNextStep';
      box.setAttribute('aria-live', 'polite');
      box.style.marginTop = '12px';
      box.style.padding = '16px';
      box.style.border = '1px solid #dedbd3';
      box.style.borderRadius = '14px';
      box.style.background = '#f7f5f0';
      printCheck.insertAdjacentElement('afterend', box);
    }
    const active = useCases?.querySelector('.chip.active')?.textContent || 'General printing';
    const rec = recommendationFor(active);
    box.innerHTML = `<p class="eyebrow">WHAT DO I SEND THEM?</p><strong>${rec.title}</strong><p style="margin:7px 0 0;color:#6e6b64;line-height:1.5">${rec.detail}</p>`;
  }

  function showToast(message) {
    let toast = document.getElementById('vmToast');
    if (!toast) {
      toast = document.createElement('div');
      toast.id = 'vmToast';
      toast.setAttribute('role', 'status');
      toast.setAttribute('aria-live', 'polite');
      Object.assign(toast.style, {
        position: 'fixed', left: '50%', bottom: '24px', transform: 'translateX(-50%)', zIndex: '9999',
        maxWidth: 'min(92vw,560px)', padding: '14px 18px', borderRadius: '12px', background: '#141414', color: '#fff',
        boxShadow: '0 14px 40px rgba(0,0,0,.2)', fontSize: '.92rem', lineHeight: '1.4'
      });
      document.body.appendChild(toast);
    }
    toast.textContent = String(message);
    toast.hidden = false;
    clearTimeout(showToast.timer);
    showToast.timer = setTimeout(() => { toast.hidden = true; }, 5000);
  }

  window.alert = showToast;

  exportButtons.forEach(button => button.addEventListener('click', () => { exportIntent = true; }));
  if (authDialog) new MutationObserver(() => {
    if (authDialog.open && exportIntent && authError && localStorage.getItem('vm_free_project_export_used') === '1') {
      authError.textContent = 'Your free project export has been used. Sign in or create an account to use purchased export credits.';
      exportIntent = false;
    }
  }).observe(authDialog, { attributes: true, attributeFilter: ['open'] });

  if (downloadAll) downloadAll.textContent = 'Download printer package (.ZIP)';
  if (authTitle) new MutationObserver(syncAuthCopy).observe(authTitle, { childList: true, characterData: true, subtree: true });
  if (authToggle) authToggle.addEventListener('click', () => queueMicrotask(syncAuthCopy));
  if (printCheck) new MutationObserver(syncNextStep).observe(printCheck, { attributes: true, childList: true, subtree: true });
  if (useCases) useCases.addEventListener('click', () => queueMicrotask(syncNextStep));
  syncAuthCopy();
  syncNextStep();
})();
