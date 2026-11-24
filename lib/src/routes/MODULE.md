# routes

**Path:** `lib/src/routes/` · **Layer:** feature shell

`app_router.dart` declares the route tree (auto_route, codegen → `app_router.gr.dart`, git-ignored). `appRouterProvider` is keepAlive.

| Route | Path | Page |
| --- | --- | --- |
| `SplashRoute` | `/` (initial) | `src/splash/ui/splash_page.dart` |
| `HomeRoute` | `/home` | `src/home/ui/home_page.dart` (tabs below) |
| ↳ `DashboardRoute` | `dashboard` (initial tab) | `src/dashboard/ui/dashboard_page.dart` |
| ↳ `LeadsRoute` | `leads` | `src/leads/ui/leads_page.dart` |
| ↳ `CallsRoute` | `calls` | `src/calls/ui/calls_page.dart` |
| ↳ `FollowUpsRoute` | `follow-ups` | `src/follow_ups/ui/follow_ups_page.dart` |
| ↳ `SettingsRoute` | `settings` | `src/settings/ui/settings_page.dart` |
| `SharedInboxRoute` | `/shared-inbox` | `src/recordings/ui/shared_inbox_page.dart` |

No guards — there is no login. Adding a page: `@RoutePage()` → register here → run codegen.
