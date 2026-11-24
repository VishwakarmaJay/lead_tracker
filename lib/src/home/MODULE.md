# home

**Path:** `lib/src/home/` · **Layer:** feature shell

`HomePage` (`HomeRoute`) is an `AutoTabsRouter` with a Material 3 `NavigationBar`: Dashboard, Leads, Calls, Follow-ups, Settings. The `PatchBanner` (from `src/update`) sits above the navigation bar so it shows on every tab.

It also listens to `sharedInboxProvider`: when a share arrives while the app is open, it pushes `SharedInboxRoute`.
