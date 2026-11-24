# splash

**Path:** `lib/src/splash/` · **Layer:** feature

- `startupProvider` (keepAlive) — everything that must finish before the tabs open: open the database (create/migrate), load settings, pull shares queued by a cold-start share. Milestone 6 adds notifications.
- `SplashPage` (`SplashRoute`, initial) — shows `AppLoader`, then `replaceAll([HomeRoute, SharedInboxRoute?])`. On failure shows the `AppException` message (e.g. "saved by a newer version") with Retry, which re-opens the database too.
