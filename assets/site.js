// NECTAR LAB — shared site behaviors
// - Nav scroll state
// - Theme toggle: AUTO → LIGHT → DARK → AUTO (persists)
// - Fade-up intersection observer
// - Active nav link

(function () {
  // Theme
  const tt = document.getElementById('themeToggle');
  const order = ['auto', 'light', 'dark'];
  let cur = localStorage.getItem('nl-theme') || 'auto';
  const apply = (m) => {
    if (m === 'auto') document.documentElement.removeAttribute('data-theme');
    else document.documentElement.setAttribute('data-theme', m);
    if (tt) tt.textContent = m.toUpperCase();
    localStorage.setItem('nl-theme', m);
  };
  apply(cur);
  if (tt) tt.addEventListener('click', () => { cur = order[(order.indexOf(cur) + 1) % order.length]; apply(cur); });

  // Nav scroll state
  const nav = document.getElementById('nav');
  if (nav) {
    const onScroll = () => nav.classList.toggle('scrolled', window.scrollY > 8);
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  // Fade-up observer
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } });
  }, { threshold: 0.12, rootMargin: '0px 0px -50px 0px' });
  document.querySelectorAll('.fade-up').forEach(el => io.observe(el));

  // Active nav link by data-page attr on <body>
  const page = document.body.dataset.page;
  if (page) {
    const link = document.querySelector(`[data-nav="${page}"]`);
    if (link) link.setAttribute('aria-current', 'page');
  }
})();
