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
| `LeadDetailRoute(leadId)` | `/leads/:id` | `src/leads/ui/lead_detail_page.dart` |
| `LeadFormRoute(leadId?)` | `/lead-form` | `src/leads/ui/lead_form_page.dart` |
| `ImportRoute` | `/import` | `src/imports/ui/import_page.dart` |
| `SharedInboxRoute` | `/shared-inbox` | `src/recordings/ui/shared_inbox_page.dart` |
| `RecordingImportRoute(recording, initialLeadId?)` | `/recording-import` | `src/recordings/ui/recording_import_page.dart` |
| `RecordingPlayerRoute(recordingId)` | `/recordings/:id` | `src/recordings/ui/recording_player_page.dart` |

No guards — there is no login. Adding a page: `@RoutePage()` → register here → run codegen.

`test/routes/app_router_test.dart` fails if any `@RoutePage()` in `lib/` is missing from `AppRouter.routes` (codegen still creates the route class, so a missing registration only fails at runtime with "Failed to navigate to XRoute").
