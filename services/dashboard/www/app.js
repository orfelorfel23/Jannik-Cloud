// Jannik-Cloud Hub Application Logic
document.addEventListener('DOMContentLoaded', () => {
  let appData = null;
  let currentCategory = 'all';
  let searchQuery = '';

  const searchInput = document.getElementById('search-input');
  const clearSearchBtn = document.getElementById('clear-search');
  const categoryFilters = document.getElementById('category-filters');
  const servicesContainer = document.getElementById('services-container');
  const emptyState = document.getElementById('empty-state');
  const resetFilterBtn = document.getElementById('reset-filter-btn');
  const statActiveCount = document.getElementById('stat-active-count');

  // Fetch Dashboard Data
  async function loadData() {
    try {
      const response = await fetch('data.json');
      if (!response.ok) throw new Error('Data fetch failed');
      appData = await response.json();
      initUI();
    } catch (err) {
      console.warn('Could not load data.json, using fallback data', err);
      // Try to load again or show error
      servicesContainer.innerHTML = `
        <div class="empty-state">
          <i class="fa-solid fa-triangle-exclamation"></i>
          <h3>Dienste-Daten konnten nicht geladen werden</h3>
          <p>Bitte führe <code>deploy_script.sh</code> auf dem Server aus, um die Dashboard-Daten zu generieren.</p>
        </div>
      `;
    }
  }

  function initUI() {
    if (!appData) return;

    // Update active services count
    statActiveCount.textContent = appData.activeCount || 0;

    // Build Category Filter Chips
    buildFilterChips();

    // Render Services
    renderServices();

    // Setup Event Listeners
    setupEventListeners();
  }

  function buildFilterChips() {
    // Keep "All" chip
    categoryFilters.innerHTML = `
      <button class="filter-chip ${currentCategory === 'all' ? 'active' : ''}" data-category="all">
        <i class="fa-solid fa-layer-group"></i> Alle (${appData.activeCount || 0})
      </button>
    `;

    appData.categories.forEach(cat => {
      const count = cat.services.length;
      const chip = document.createElement('button');
      chip.className = `filter-chip ${currentCategory === cat.name ? 'active' : ''}`;
      chip.dataset.category = cat.name;
      chip.innerHTML = `<i class="fa-solid ${cat.icon || 'fa-cubes'}"></i> ${cat.name} (${count})`;
      categoryFilters.appendChild(chip);
    });
  }

  function renderServices() {
    if (!appData) return;

    let totalVisible = 0;
    let html = '';

    appData.categories.forEach(cat => {
      // Check if category matches filter
      if (currentCategory !== 'all' && currentCategory !== cat.name) {
        return;
      }

      // Filter services by search query
      const filteredServices = cat.services.filter(s => {
        if (!searchQuery) return true;
        const q = searchQuery.toLowerCase();
        const matchTitle = s.title.toLowerCase().includes(q);
        const matchDesc = s.description.toLowerCase().includes(q);
        const matchId = s.id.toLowerCase().includes(q);
        const matchDomains = (s.domains || []).some(d => d.toLowerCase().includes(q));
        return matchTitle || matchDesc || matchId || matchDomains;
      });

      if (filteredServices.length === 0) return;

      totalVisible += filteredServices.length;

      html += `
        <section class="category-group">
          <div class="category-header">
            <div class="category-icon-wrapper">
              <i class="fa-solid ${cat.icon || 'fa-cubes'}"></i>
            </div>
            <h2 class="category-title">${escapeHtml(cat.name)}</h2>
            <span class="category-count">${filteredServices.length}</span>
          </div>

          <div class="service-grid">
            ${filteredServices.map(s => renderServiceCard(s)).join('')}
          </div>
        </section>
      `;
    });

    if (totalVisible === 0) {
      servicesContainer.innerHTML = '';
      emptyState.style.display = 'block';
    } else {
      emptyState.style.display = 'none';
      servicesContainer.innerHTML = html;
    }
  }

  function renderServiceCard(svc) {
    const domainText = svc.domains && svc.domains.length > 0 ? svc.domains[0] : '';
    return `
      <a href="${escapeHtml(svc.url)}" target="_blank" rel="noopener" class="service-card" data-service-id="${escapeHtml(svc.id)}">
        <div class="card-top">
          <div class="card-icon">
            <i class="fa-solid ${escapeHtml(svc.icon || 'fa-cube')}"></i>
          </div>
          <div class="card-actions">
            <span class="status-dot" title="Aktiv"></span>
            <i class="fa-solid fa-arrow-up-right-from-square external-arrow"></i>
          </div>
        </div>
        <div class="card-title">${escapeHtml(svc.title)}</div>
        ${domainText ? `<div class="card-domain">${escapeHtml(domainText)}</div>` : ''}
        <div class="card-desc">${escapeHtml(svc.description)}</div>
      </a>
    `;
  }

  function setupEventListeners() {
    // Search input
    searchInput.addEventListener('input', (e) => {
      searchQuery = e.target.value.trim();
      clearSearchBtn.style.display = searchQuery ? 'block' : 'none';
      renderServices();
    });

    // Clear search
    clearSearchBtn.addEventListener('click', () => {
      searchInput.value = '';
      searchQuery = '';
      clearSearchBtn.style.display = 'none';
      searchInput.focus();
      renderServices();
    });

    // Category click
    categoryFilters.addEventListener('click', (e) => {
      const chip = e.target.closest('.filter-chip');
      if (!chip) return;

      document.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');

      currentCategory = chip.dataset.category;
      renderServices();
    });

    // Reset button in empty state
    resetFilterBtn.addEventListener('click', () => {
      searchInput.value = '';
      searchQuery = '';
      clearSearchBtn.style.display = 'none';
      currentCategory = 'all';
      buildFilterChips();
      renderServices();
    });

    // Global keyboard shortcut ('/' to search, 'Escape' to clear)
    document.addEventListener('keydown', (e) => {
      if (e.key === '/' && document.activeElement !== searchInput) {
        e.preventDefault();
        searchInput.focus();
        searchInput.select();
      } else if (e.key === 'Escape' && document.activeElement === searchInput) {
        searchInput.value = '';
        searchQuery = '';
        clearSearchBtn.style.display = 'none';
        searchInput.blur();
        renderServices();
      }
    });
  }

  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  // Start initialization
  loadData();
});
