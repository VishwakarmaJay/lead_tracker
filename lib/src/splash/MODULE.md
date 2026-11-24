# splash

**Path:** `lib/src/splash/` · **Layer:** feature

- `startupProvider` (keepAlive) — everything that must finish before the tabs open. Milestone 0: pulls shares queued by a cold-start share. Milestone 1 adds opening the database; Milestone 6 adds notifications.
- `SplashPage` (`SplashRoute`, initial) — shows `AppLoader`, then `replaceAll([HomeRoute, SharedInboxRoute?])`. On failure shows `AppError` with Retry (invalidates `startupProvider`).
