# home

**Path:** `lib/src/home/` · **Layer:** feature shell

`HomePage` (`HomeRoute`) is an `AutoTabsRouter` with a Material 3 `NavigationBar`: Dashboard, Leads, Calls, Follow-ups, Settings. The `PatchBanner` (from `src/update`) sits above the navigation bar so it shows on every tab.

It also hosts app-wide reactions:

- listens to `sharedInboxProvider` and pushes `SharedInboxRoute` when a share arrives while the app is open;
- an `AppLifecycleListener`: on hide → `pendingCallTracker.markLeftApp()`; on resume → if a call was started from the app, opens `showLogCallSheet` with the dial time filled in.
