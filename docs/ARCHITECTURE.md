# Architecture — Lead Tracker

Lead Tracker follows the **hedged-core-app** structure: feature-first folders
under `lib/src/`, shared infrastructure in `lib/core/`, Riverpod 3 with codegen,
and `auto_route`. Hedged talks to a REST API; Lead Tracker talks to a local
SQLite database, so each feature also gets a `data/` folder holding its models
and repository. Keep it pragmatic: don't create empty folders or interfaces for
every class.

## 1. Folder layout

```text
lib/
├── main.dart                 # bootstrap: binding, portrait lock, runApp(ProviderScope(App()))
├── app.dart                  # MaterialApp.router, light/dark theme, scaffoldMessengerKey
├── core/                     # cross-cutting infra — never imports from src/
│   ├── constants/            # keys.dart (scaffoldMessengerKey), app constants
│   ├── database/             # app_database.dart, schema v1, migrations/
│   ├── error/                # app_exception.dart (AppException + ErrorType)
│   ├── extension/            # context, future (.guard), async_value (.unfold), log, datetime, string
│   ├── instances/            # keepAlive singletons: database, notifications, share bridge channel, shorebird
│   └── utils/                # phone_normalizer.dart, file helpers, validation mixin
└── src/                      # all features
    ├── routes/               # app_router.dart (+ .gr.dart), wrappers/
    ├── theme/                # app_theme, app_color (ThemeExtension), app_text_theme, theme provider
    ├── shared/
    │   ├── components/       # AppLoader, AppError, AppEmptyWidget, AppConfirmation, app_snack_bar
    │   └── providers/
    ├── splash/               # startup_provider: open DB, init notifications, drain pending shares
    ├── home/                 # TabsRouter shell + PatchBanner slot
    ├── update/               # Shorebird patch notifier + PatchBanner (restart after patch)
    ├── dashboard/
    ├── leads/
    ├── imports/              # XLSX/CSV import flow
    ├── calls/                # manual call logs (+ optional system call-log sync)
    ├── recordings/           # share/picker import, playback
    ├── follow_ups/
    └── settings/
```

Every feature folder has the same shape:

```text
src/<feature>/
├── MODULE.md                  # what it does, key files, providers, routes, depends on
├── ui/
│   ├── <feature>_page.dart    # @RoutePage screens
│   ├── sections/              # large page regions
│   ├── components/            # small feature-local widgets
│   └── bottomsheets/
├── providers/
│   ├── <thing>_provider.dart  # @riverpod functions / notifiers
│   ├── <thing>_state.dart     # immutable state classes with copyWith
│   └── *.g.dart               # generated, git-ignored
├── data/                      # Lead Tracker addition (not in hedged)
│   ├── models/                # immutable models, fromMap/toMap, enums
│   └── <feature>_repository.dart
└── services/                  # only when a workflow spans repo + files/platform
```

Only create the subfolders a feature actually needs.

## 2. Dependency direction

```text
ui (ConsumerWidget pages, sections, components)
        │  ref.watch / ref.read
        ▼
providers (@riverpod functions + notifiers)
        │
        ▼
services (import, attach recording, schedule reminder)   ← optional
        │
        ▼
data/ repositories ──► core/instances (database, notifications, share bridge)
```

Rules:

- `core` never imports from `src`.
- Features talk to SQLite only through their own repository. Another feature
  may read a repository through its provider (e.g. dashboard reads lead and
  follow-up repositories) but never imports another feature's `ui/`.
- Widely shared widgets/providers move to `src/shared/`.
- Widgets don't import `sqflite`, run SQL, copy files, or parse spreadsheets.
- Repositories return typed models, never raw maps.
- Android-specific behaviour sits behind an interface in `core/instances/`.

## 3. Core pieces (adapted from hedged)

### `AppException` and `.guard()`

One error type that features catch, as in hedged:

```dart
enum ErrorType { database, file, permission, parse, platform, other }

class AppException implements Exception {
  AppException({required this.message, required this.type, this.data});
  final String message;
  final ErrorType type;
  final Object? data;
}
```

`core/extension/future.dart` provides `Future<T>.guard<T>()`, which maps
`DatabaseException` → `database`, `FileSystemException` → `file`,
`PlatformException` → `platform` (or `permission` by code), `FormatException`
→ `parse`, anything else → `other`. It logs with `.logError()` and returns a
user-safe message. Hedged's Dio/Firebase branches are not needed.

### `.unfold()` on `AsyncValue`

Same as hedged's `async_value.dart`: error → `AppError`, loading → `AppLoader`,
data → builder. Show detailed errors only in debug builds.

### `context.colors` / `context.text`

`BaseColorExtension` and a typography extension registered on `ThemeData`, read
through `context.colors` / `context.text` (hedged's `context.dart`). Light and
dark themes; the chosen mode lives in a `keepAlive` theme notifier stored in the
`app_settings` table.

### Logging

`.logInfo()`, `.logSuccess()`, `.logWarning()`, `.logError()` extensions on
`Object?` using `dart:developer` `log` (hedged's `log.dart`). No Crashlytics.
Never log phone numbers, notes, or file paths.

### `keepAlive` providers

Only: `appDatabaseProvider`, `appRouterProvider`, `startupProvider`,
`appThemeModeProvider`, `notificationServiceProvider`, `shareBridgeProvider`,
`shorebirdProvider`. Everything else auto-disposes.

## 4. Routing (auto_route)

- `src/routes/app_router.dart`: `@AutoRouterConfig(replaceInRouteName: 'Page,Route')`,
  exposed through a `keepAlive` `appRouterProvider` (like hedged).
- Routes: `SplashRoute` → `HomeRoute` (a `TabsRouter` with Dashboard, Leads,
  Calls, Follow-ups, Settings). Pushed routes: `LeadDetailRoute(id)`,
  `LeadFormRoute`, `ImportRoute`, `RecordingImportRoute`, `RecordingPlayerRoute(id)`.
- No auth/KYC/onboarding guards — there is no login. `SplashRoute` waits on
  `startupProvider` (database open, migrations, notification init, pending
  shares) before replacing itself with `HomeRoute`.
- Incoming shares received while the app is open push `RecordingImportRoute`.
- Navigate with typed routes: `context.router.push(LeadDetailRoute(id: id))`.

## 5. Core interfaces

```dart
abstract interface class LeadRepository {
  Future<List<Lead>> searchLeads(LeadQuery query);
  Future<Lead?> getLeadById(int id);
  Future<int> createLead(LeadDraft draft);
  Future<void> updateLead(Lead lead);
  Future<void> deleteLead(int id);
  Future<List<Lead>> findByNormalizedPhone(String normalizedPhone);
}

abstract interface class CallHistoryDataSource {
  Future<CallHistoryAvailability> getAvailability();
  Future<List<SystemCallRecord>> fetchSince(DateTime since);
}

abstract interface class RecordingImportService {
  Future<RecordingImportResult> importSharedFile(SharedFilePayload payload);
  Future<RecordingImportResult> importPickedFile(PickedFilePayload payload);
}
```

`findByNormalizedPhone` returns a list because several leads can share a number.
`CallHistoryDataSource` reports "unavailable" instead of throwing; manual call
logging always works.

## 6. Phone number handling

- Keep the user's original phone string; store a separate normalized value.
- Default region India (`IN`), default code `+91`, configurable in Settings.
- Don't strip a leading `+` and assume Indian.
- Test `9876543210`, `+91 98765 43210`, `09876543210`, and numbers with
  spaces, hyphens, and parentheses.
- Invalid numbers can be kept if the user chooses, but are flagged and excluded
  from automatic matching.

## 7. Excel/CSV import pipeline (`src/imports`)

1. Pick a file; copy to app cache if the picker API requires it.
2. Detect format by extension/MIME; reject unsupported files.
3. Parse the header row; show a column-mapping screen.
4. Require mapped `name` and `phone`.
5. Convert rows to `LeadImportCandidate`s; trim; keep the original phone; normalize.
6. Detect duplicates inside the file and against existing leads.
7. Show counts: valid, invalid, duplicate, skipped.
8. User confirms the strategy (skip duplicates by default; never overwrite silently).
9. Insert in one SQLite transaction / batches.
10. Show a result screen.

Support header aliases: `Name`, `Full Name`, `Phone`, `Mobile`, `Contact`,
`Company`, `Email`, `Website`, `Source`. Parsing runs off the UI thread for big
files (`compute`/isolate).

## 8. Recording import pipeline (`src/recordings`)

1. Android receives `ACTION_SEND` / `ACTION_SEND_MULTIPLE` with `audio/*`.
2. Kotlin reads `EXTRA_STREAM` / ClipData and checks the URI grant.
3. Kotlin stream-copies each `content://` URI into an app-private cache file.
4. Kotlin sends Dart: cache path, display name, MIME type, size, optional
   shared text. No caller number or call time is assumed.
5. Dart validates the file and computes SHA-256.
6. If the checksum already exists, offer to open the existing recording instead.
7. The user picks the lead (suggestions only from grounded metadata, never just
   the filename) and optionally a call log.
8. Move the file to `<documents>/recordings/lead_<id>/<generated-id>.<safe-ext>`.
9. Insert the metadata row in a transaction.
10. If the insert fails, keep the file recoverable and offer Retry/Cleanup.

Audio stays a file, never a BLOB.

## 9. Update feature (`src/update`, mirrors hedged)

- `shorebirdProvider` (`keepAlive`) exposes `ShorebirdCodePush()`.
- `Patch` notifier → `PatchStatus { hidden, available, downloading, readyToRestart }`:
  - `build()`: if Shorebird isn't available (debug builds) → `hidden`; if a patch
    is already staged → `readyToRestart`; if one is available → `available`.
    Hedged's backend-driven "silent patch" flag is dropped: no backend.
  - `download()`: set `downloading`, call `downloadUpdateIfAvailable()`, then
    confirm with `isNewPatchReadyToInstall()` before moving to `readyToRestart`.
    On error, go back to `available`.
  - `restart()`: `Restart.restartApp(mode: RestartMode.process)`.
- `PatchBanner` (`ConsumerWidget`) sits above the bottom `NavigationBar` in the
  home shell, so it shows on every tab: "A new update is available → Update",
  then "Update ready → Restart now".
- Restart is disabled while an import/recording copy/transaction is running
  (a shared `busyOperationsProvider` counter).
- Settings shows the app version (`package_info_plus`) and patch status.

## 10. Dashboard queries

Derived from SQLite every time: total leads, calls logged today, hot leads,
follow-ups due today or overdue, latest five calls, next five pending
follow-ups. No cached counters.

## 11. Failure states

Explicit UI for: database open/migration error, picker cancelled, unsupported
or malformed XLSX/CSV, invalid/duplicate rows, low storage, expired share URI,
unknown MIME type, audio copy failure, checksum duplicate, playback failure,
notification permission denied, call-log permission unavailable, patch download
failure. Never swallow exceptions; never show raw stack traces in release builds.
