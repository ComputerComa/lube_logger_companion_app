# LubeLogger Companion – Current Feature Set

## Core Experience
- Guided setup flow with secure credential storage and automatic re-entry on app launch.
- Home screen vehicle carousel with cached authenticated images, swipe indicators, and quick navigation to details.
- Offline-aware UI with connectivity banner, local caching for vehicles and record data, and graceful fallbacks when offline.
- Global settings screen with connection info, app actions, polling controls, and theme selector (Auto / Light / Dark).

## Vehicle Insights
- Vehicle detail view summarizing reminders, recent service records, and quick actions.
- Statistics dashboard with summary cards plus interactive charts (fuel cost, MPG, fuel consumption, price per gallon) powered by `fl_chart`.

## Data Entry & Management
- Full CRUD coverage for fuel, odometer, service, repair, upgrade, reminder, and tax records.
- Dynamic extra-field definitions fetched from `/api/extrafields` and rendered on relevant add forms (fuel, odometer, service, repair, upgrade, tax).
- Tag management for fuel entries with suggestions sourced from existing records.
- Pull-to-refresh and manual refresh action for all vehicle-related data.

## Automation & Background Tasks
- Polling service with configurable interval, auto-start/stop tied to authentication, and storage-backed preferences.
- Cached network image handling with self-signed certificate support and custom cache manager.

## Supporting Services
- Storage service abstraction for credentials, settings, polling, theme mode, and cached payloads.
- Connectivity monitoring for offline indicator exposure throughout the app.
- Notification service initialization scaffold for reminders and alerts (permissions handled during setup).

## Developer Tooling
- Riverpod-based provider structure with repository pattern for API access.
- Cached data helper utilities for consistent fetch/cache workflows across providers.
- Modular widget library including reusable extra-fields form section and offline banners.

