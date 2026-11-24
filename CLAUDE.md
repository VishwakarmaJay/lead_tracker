# Lead Tracker — Claude Code instructions

Personal, single-user, **Android-only** Flutter app for freelance prospecting:
import leads from XLSX/CSV, call them through the native dialer, log call notes
and outcomes, attach Google Phone call recordings, and schedule follow-ups.
All data stays on the device. Updates ship as **Shorebird** over-the-air patches
on top of a sideloaded release APK.

- **Package:** `lead_tracker` · **Version:** see `pubspec.yaml` (`version: x.y.z+build`)
- **Flutter:** `3.38.3` pinned with FVM (`.fvmrc`) — run every command as `fvm flutter …` / `fvm dart …`
- **Flavors:** none (one build)
- **Architecture reference:** follows the structure and patterns of the `hedged-core-app`
  project (feature-first `lib/src/<feature>/{ui,providers}`, `lib/core/` infra,
  Riverpod codegen, auto_route, Shorebird + restart). Lead Tracker adds a
  `data/` folder per feature because it owns a local SQLite database instead of
  a REST API.

> This file is the map and the rules. Details live in `docs/`. Each feature
> under `lib/src/` gets its own `MODULE.md` once it exists.

---

## Docs (`docs/`)

| Doc | What it covers |
| --- | --- |
| [PROJECT_DESCRIPTION](docs/PROJECT_DESCRIPTION.md) | Product, screens, MVP scope, non-goals, acceptance criteria |
| [STACK](docs/STACK.md) | Flutter/FVM pin, packages and versions, codegen tooling |
| [ARCHITECTURE](docs/ARCHITECTURE.md) | Folder layout, layers, core helpers, import pipelines |
| [CODE_PRACTICES](docs/CODE_PRACTICES.md) | Riverpod/rebuild rules, error handling, what to avoid |
| [DATABASE_SCHEMA](docs/DATABASE_SCHEMA.md) | SQLite tables, indexes, migration rules |
| [ANDROID_INTEGRATIONS](docs/ANDROID_INTEGRATIONS.md) | Google Phone share bridge, call-log POC, dialer, notifications, internet permission |
| [BUILD_AND_RELEASE](docs/BUILD_AND_RELEASE.md) | Codegen, signing, Shorebird release APK, patches, restart-after-patch |
| [IMPLEMENTATION_PLAN](docs/IMPLEMENTATION_PLAN.md) | Milestones in build order |
| [DEVICE_TEST_CHECKLIST](docs/DEVICE_TEST_CHECKLIST.md) | Manual tests on the realme phone: share POC, signing, Shorebird patch → Restart now |
| [poc/CALL_LOG_POC](docs/poc/CALL_LOG_POC.md) | Procedure and results for the `READ_CALL_LOG` investigation |
| [REFERENCES](docs/REFERENCES.md) | Official links |

---

## Tech stack (summary — full list in STACK.md)

| Concern | Choice |
| --- | --- |
| State + DI | Riverpod 3 with codegen (`riverpod_annotation` + `riverpod_generator`) |
| Routing | `auto_route` (codegen, `TabsRouter` home shell) |
| Database | SQLite via `sqflite`, wrapped by per-feature repositories |
| Files | `path_provider` + `path`; recordings in app-private storage |
| Import | `excel`, `csv`, `file_picker` |
| Audio | `just_audio` (playback only), `crypto` (SHA-256) |
| Reminders | `flutter_local_notifications` + `timezone` |
| OTA updates | `shorebird_code_push` + `restart_app` |
| Android bridge | Small Kotlin share-intent receiver in `MainActivity` |

Codegen: `fvm dart run build_runner build --delete-conflicting-outputs`
regenerates `*.g.dart` (Riverpod) and `*.gr.dart` (auto_route). Generated files
are **git-ignored** (same as hedged) — regenerate after every clone, pull, or
provider/route change. **Never edit generated files by hand.**

---

## 1. Product boundaries

- Single-user personal app, not a commercial CRM. Android only.
- Flutter UI, SQLite database, private on-device file storage.
- No backend, login, cloud sync, Firebase, Supabase, Appwrite, analytics, ads,
  paid SDKs, AI APIs, or network-dependent core workflow.
- **The one network exception is Shorebird.** The app may hold the
  `INTERNET` permission so the Shorebird updater can check for and download
  patches. No app code may make network requests, and no user data (leads,
  notes, call logs, recordings) may ever leave the device. Every core feature
  must work offline.
- XLSX and CSV import are required.
- Google Phone records calls. Lead Tracker only receives a recording the user
  shares and imports it.
- Do not implement microphone capture, cellular call audio capture, call
  interception, root-only access, or any workaround that bypasses Android security.

## 2. Critical Android permission rules

`READ_CALL_LOG` is a hard-restricted Android permission. It cannot be held
unless the installer on record allowlists it. Google Play further restricts Call
Log permissions to apps registered as the default Phone or Assistant handler.

1. Do not assume a runtime permission dialog is enough.
2. Do not make call-log sync a dependency for app usability.
3. Prove it in the Milestone 0 POC on the real realme 11 Pro+ 5G first.
4. Keep the integration behind `CallHistoryDataSource` with an availability state.
5. Do not add call-log permissions to the final manifest unless the POC found a
   permitted way to grant them and the user explicitly wants the feature.
6. Never request `WRITE_CALL_LOG`, `PROCESS_OUTGOING_CALLS`,
   `READ_PHONE_NUMBERS`, contacts, microphone, `MANAGE_EXTERNAL_STORAGE`, or
   `CALL_PHONE`.
7. If unavailable, manual call logging and recording attachment are the supported path.

Do not tell the user call history will sync automatically unless the
physical-device test passes.

## 3. Google Phone recording integration

- The user configures recording in Google Phone; Lead Tracker cannot toggle it.
- Lead Tracker is a target for `ACTION_SEND` / `ACTION_SEND_MULTIPLE` with `audio/*`.
- Handle cold start (`onCreate`) and warm start (`onNewIntent`); queue shares
  until Flutter is listening.
- Copy the `content://` stream into app-private cache while the grant is valid,
  using streaming. Never store the external URI as the permanent path.
- Pass only the cached path, display name, MIME type, and size to Dart.
- Flutter moves the file into permanent storage and inserts metadata. If that
  fails, keep a recoverable temp file and show an actionable error.
- Always ask the user to confirm the lead. A suggested match is not a confirmed match.
- Provide an in-app file-picker fallback.
- Do not read Google Phone's private folders. Do not claim import is automatic.
- The share bridge is native code: changing it needs a **new release APK**, not a
  Shorebird patch.

## 4. Architecture rules (details in ARCHITECTURE.md)

- Feature-first, hedged-style: `lib/src/<feature>/ui/`, `providers/`, `data/`.
  Cross-cutting infra in `lib/core/`; shared widgets/providers in `lib/src/shared/`.
- Dependency direction: `src/<feature>` → `src/shared` → `core`. `core` never
  imports a feature; its only `src/` imports are `src/theme` and
  `src/shared/components` (for `context.colors` and `.unfold()`, as in hedged).
  Features don't reach into each other's `ui/`.
- **Widgets never run SQL, copy files, parse spreadsheets, or hold permission
  logic.** SQL lives only in `data/` repositories; workflows (import, attach
  recording, schedule reminder) live in services/notifiers.
- All providers use `@riverpod` / `@Riverpod(keepAlive: true)`. `keepAlive` only
  for session-long singletons: database, router, startup, theme mode,
  Shorebird, notifications, share bridge.
- Repositories return typed immutable models with explicit `fromMap`/`toMap`
  and `copyWith`. Enums persist stable string values.
- Every repository/service call that can fail goes through `.guard()` and
  surfaces an `AppException`. Render `AsyncValue` with `.unfold()` or
  `.when` — never `.value!`.
- Theme via `context.colors` / `context.text`, not `Theme.of(context)` directly.
- Logging via `.logInfo()` / `.logError()` extensions. No `print`.
- UTC Unix milliseconds in the database; local time only in the UI.
- Phone normalisation lives in one tested utility. Keep the original string.
  Default region India (`IN`, `+91`), configurable. Never destroy an
  international prefix.
- Schema starts at version 1; every change is a migration. Use transactions for
  multi-row writes and parameterised SQL only. No audio BLOBs in SQLite.

## 5. Shorebird and restart-after-patch

- Release builds are made with `shorebird release android --artifact apk`
  (never plain `flutter build apk` for something you install), so the APK can
  receive patches. See BUILD_AND_RELEASE.md.
- The `update` feature mirrors hedged's: a `Patch` notifier with states
  `hidden → available → downloading → readyToRestart`, and a `PatchBanner`
  shown above the home bottom navigation.
- After a patch is downloaded, the banner offers **Restart now**, which calls
  `Restart.restartApp(mode: RestartMode.process)`. A Shorebird patch only loads
  on a fresh native process; the default restart mode only recreates the
  activity, so the patch would be silently skipped.
- Confirm the patch is staged (`isNewPatchReadyToInstall`) before offering
  the restart. If download fails, return to `available` so the user can retry.
- **Patches can only change Dart code and compatible assets.** Kotlin,
  `AndroidManifest.xml`, Gradle, native plugin changes, and new plugins with
  native code need a new release.
- **Database schema changes ship in a full release, not a patch.** A patch can be
  rolled back from the Shorebird console; older code would then open a newer
  schema and fail.
- Never restart the app while an import, recording copy, or database
  transaction is running. Disable **Restart now** while one is in progress.

## 6. Dependency discipline

- Use STACK.md as the baseline. Versions must resolve on Flutter 3.38.3.
- Before adding a dependency, check pub.dev docs, Android support, license,
  minimum SDK, and maintenance.
- Fast-moving packages (`file_picker`, `flutter_local_notifications`,
  `shorebird_code_push`): read the installed version's API — don't copy old snippets.
- Don't add a package for something the Flutter SDK or a small Kotlin bridge
  can do cleanly. Don't add `permission_handler` by default.
- Commit `pubspec.lock`.

## 7. UI requirements

Bottom tabs: **Dashboard, Leads, Calls, Follow-ups, Settings** (auto_route
`TabsRouter`). Lead detail, recording import, and recording playback are
pushed routes. Settings shows the app version and update status.

- Material 3, consistent spacing/typography, explicit loading/empty/error states
  via shared `AppLoader`, `AppError`, `AppEmptyWidget`.
- Long lists use `ListView.builder`/slivers.
- Validate name and phone in forms. Confirm destructive actions (shared
  `AppConfirmation`).
- No decorative charts or extra screens.

## 8. Data integrity and privacy

- Keep all user data local. Never transmit contacts, call logs, notes, or recordings.
- Never auto-send WhatsApp messages, emails, or recordings.
- Respect recording consent/notice rules; never suppress Google Phone's announcement.
- Recording imports are user-initiated. Store them under
  `recordings/lead_<id>/<generated-id>.<ext>`; never trust incoming filenames as paths.
- Compute SHA-256 and size for dedupe/integrity. Never delete the source in Google Phone.
- Never silently orphan audio when a lead is deleted (soft delete or block until
  recordings are reassigned/deleted).
- Never log full phone numbers, notes, file contents, or recording paths.
- The release keystore and `key.properties` are never committed.

## 9. Testing rules

For every feature: unit tests for logic, repository tests on a temporary
database, widget tests for key states where practical, then
`fvm dart format .`, `fvm flutter analyze`, `fvm flutter test`.

For Android integrations and Shorebird patching, write a reproducible manual
checklist. Do not mark them complete from mocked tests alone.

## 10. Workflow and definition of done

- Follow IMPLEMENTATION_PLAN.md in order, one milestone at a time.
- Inspect the project before changing files; preserve working configuration.
- Do not invent API fields, permissions, or package methods — check the
  installed package source/docs.
- If a platform restriction blocks a feature, stop, report it, and implement the
  documented fallback.
- A milestone is done when codegen is clean, the code compiles, format/analyze/
  tests pass, manual device steps are documented, the feature's `MODULE.md`
  exists, and no unrelated feature or dependency was added.
- After each milestone, summarise files changed, commands run, results,
  unresolved risks, and the next milestone.

---

## Where does new code go?

| You're adding… | Put it in |
| --- | --- |
| A new screen | `lib/src/<feature>/ui/<name>_page.dart` (`@RoutePage`), register in `src/routes/app_router.dart`, rerun codegen |
| Feature state / a fetch | `lib/src/<feature>/providers/` as `@riverpod` |
| SQL / a query | `lib/src/<feature>/data/<feature>_repository.dart` |
| A model | `lib/src/<feature>/data/models/` (immutable, `fromMap`/`toMap`) |
| A widget used by 2+ features | `lib/src/shared/components/` |
| App-wide state | `lib/src/shared/providers/` |
| A long-lived singleton (DB, notifications, share bridge, Shorebird) | `lib/core/instances/` as a `keepAlive` provider |
| A helper or extension | `lib/core/utils/` or `lib/core/extension/` |
| A color / text style | `lib/src/theme/`, exposed via `context.colors` / `context.text` |
