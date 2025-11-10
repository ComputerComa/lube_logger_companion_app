---
layout: default
title: Lube Logger Companion App
description: A Flutter companion experience for the self-hosted LubeLogger platform, optimized for vehicle fleets, fuel tracking, and maintenance analytics.
---

<section class="hero">
  <div class="container">
    <span class="pill">Flutter • Riverpod • GitHub Pages</span>
    <h1 class="hero-title">Keep every vehicle insight at your fingertips.</h1>
    <p class="hero-subtitle">
      The Lube Logger Companion App pairs with your self-hosted backend to track fuel entries, service
      history, maintenance plans, and health metrics—online or off. Built with Flutter, Riverpod, and a
      caching strategy tailored for technicians on the move.
    </p>
    <div class="hero-actions">
      <a class="button button-primary" href="https://github.com/{{ site.github_username }}/{{ site.github_repo }}" target="_blank">
        <span>View Source</span> →
      </a>
      <a class="button button-ghost" href="#features">Explore Features</a>
    </div>
  </div>
</section>

<section id="features">
  <div class="container">
    <h2 class="section-heading">Why mechanics and managers love it</h2>
    <p class="section-lead">
      Purpose-built UI paired with a resilient offline-first architecture delivers the reliability the garage floor requires.
    </p>
    <div class="cards-grid">
      <article class="card">
        <span class="card-icon">📊</span>
        <h3 class="card-title">Insightful analytics</h3>
        <p>
          `fl_chart` powered dashboards surface MPG, fuel spend, consumption trends, and plan progress in engaging visualizations.
        </p>
      </article>
      <article class="card">
        <span class="card-icon">📱</span>
        <h3 class="card-title">Swipe card UX</h3>
        <p>
          Vehicles appear as tactile swipeable cards with cached imagery, plan summaries, and quick actions for technicians.
        </p>
      </article>
      <article class="card">
        <span class="card-icon">📡</span>
        <h3 class="card-title">Smart polling</h3>
        <p>
          Configurable refresh intervals keep reminders, fuel records, and service logs synced without overloading the server.
        </p>
      </article>
      <article class="card">
        <span class="card-icon">📝</span>
        <h3 class="card-title">Dynamic extra fields</h3>
        <p>
          Auto-generated forms map backend-driven schemas to UI components, handling text, numeric, boolean, and date inputs.
        </p>
      </article>
      <article class="card">
        <span class="card-icon">🌐</span>
        <h3 class="card-title">Offline ready</h3>
        <p>
          Cached datasets and connection-aware providers ensure the team can review the latest records even when disconnected.
        </p>
      </article>
      <article class="card">
        <span class="card-icon">🎨</span>
        <h3 class="card-title">Adaptive theming</h3>
        <p>
          Built-in light, dark, and system modes keep the interface legible in shop bays, offices, and field work.
        </p>
      </article>
    </div>
  </div>
</section>

<section id="architecture">
  <div class="container feature-columns">
    <div class="feature-card">
      <span class="badge">Architecture</span>
      <h3>Flutter + Riverpod foundation</h3>
      <p>
        Feature modules rely on Riverpod providers to orchestrate API calls, caching, and optimistic updates. Domain models capture every record
        type—fuel, service, repair, tax, upgrade, and plan entries—ensuring data parity with the LubeLogger backend.
      </p>
      <ul>
        <li>GoRouter handles deep-linking and setup skips</li>
        <li>Custom cache helpers wrap SharedPreferences and connectivity checks</li>
        <li>Polling service manages background refresh and invalidation</li>
      </ul>
    </div>
    <div class="feature-card">
      <span class="badge">API coverage</span>
      <h3>Repository orchestrated API clients</h3>
      <p>
        `LubeLoggerRepository` centralizes CRUD operations for every endpoint and surfaces domain-specific helpers like version checks and plan record
        normalization. Extra field definitions are retrieved once and fanned out to the relevant form widgets.
      </p>
      <ul>
        <li>Basic auth via Secure Storage</li>
        <li>Self-signed certificate friendly HTTP client</li>
        <li>Version provider powers “Check for updates” UI</li>
      </ul>
    </div>
  </div>
</section>

<section id="screens">
  <div class="container">
    <h2 class="section-heading">Preview the experience</h2>
    <p class="section-lead">
      Swap in your final screenshots below—card layouts, charts, and plan boards keep stakeholders informed at a glance.
    </p>
    <div class="feature-columns">
      <div class="feature-card">
        <h3>Vehicle Overview</h3>
        <p>Swipeable cards deliver critical stats with quick actions for fuel, service, and plan management.</p>
        <p class="placeholder">Add screenshot: <code>assets/images/vehicle-cards.jpg</code></p>
      </div>
      <div class="feature-card">
        <h3>Statistics Dashboard</h3>
        <p>Chart MPG trends, fuel costs, and consumption per vehicle with configurable time windows.</p>
        <p class="placeholder">Add screenshot: <code>assets/images/stats-dashboard.jpg</code></p>
      </div>
      <div class="feature-card">
        <h3>Plan Records</h3>
        <p>Kanban-like summaries and dedicated forms keep upgrades, repairs, and testing tasks moving forward.</p>
        <p class="placeholder">Add screenshot: <code>assets/images/plan-records.jpg</code></p>
      </div>
    </div>
  </div>
</section>

<section id="roadmap">
  <div class="container timeline">
    <h2 class="section-heading">Roadmap</h2>
    <p class="section-lead">
      The companion app is ever evolving. Track what’s shipped and what’s next.
    </p>
    <ul>
      <li><strong>✅ Q3 2025:</strong> Offline caching, swipeable vehicle cards, dynamic extra fields.</li>
      <li><strong>✅ Q4 2025:</strong> Plan records stack, charts, theme selector, context menus.</li>
      <li><strong>🔄 In Progress:</strong> GitHub Pages documentation & marketing site (you’re looking at it!).</li>
      <li><strong>🧭 Up Next:</strong> Push notification reminder integration, multi-tenant backend support.</li>
    </ul>
  </div>
</section>

<section id="cta">
  <div class="container">
    <div class="cta-panel">
      <h2>Ready to explore the code?</h2>
      <p>
        Clone the repository, run <code>flutter pub get</code>, and start logging data with the LubeLogger Companion App. The README walks through backend configuration and credential storage.
      </p>
      <div class="hero-actions">
        <a class="button button-primary" href="https://github.com/{{ site.github_username }}/{{ site.github_repo }}" target="_blank">
          GitHub Repository
        </a>
        <a class="button button-ghost" href="mailto:{{ site.contact_email }}">Request a demo</a>
      </div>
    </div>
  </div>
</section>

