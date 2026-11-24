# Implementation Plan — Lead Tracker

Build one milestone at a time. Do not generate the whole app in one pass.

Shorebird is set up in Milestone 0, so the very first APK installed on the
phone can receive patches. After that, each milestone ships either as a
**patch** (Dart-only changes) or a **new release** (native code, manifest,
Gradle, new plugins with native code, or a database schema change). Each
milestone below says which one it needs.

## Milestone 0 — Bootstrap, architecture skeleton, Shorebird, device POCs

### Deliverables

**Toolchain and project**
- Pin Flutter 3.38.3 with FVM (`.fvmrc`); confirm with `fvm flutter doctor -v`.
- Decide the final Android `applicationId` (currently `com.example.lead_tracker`). It must not change after the first release: a new id is a different app and the old one's local data would be stranded.
- Add the baseline dependencies from `STACK.md` that the skeleton needs (Riverpod + generator, auto_route + generator, build_runner, `shorebird_code_push`, `restart_app`, `package_info_plus`). Commit `pubspec.lock`.
- Copy hedged's `analysis_options.yaml` rules (without `custom_lint`). Git-ignore `*.g.dart` / `*.gr.dart`.

**Architecture skeleton (hedged-style)**
- `lib/core/`: `error/app_exception.dart`, `extension/` (`future.dart` `.guard()`, `async_value.dart` `.unfold()`, `context.dart`, `log.dart`), `constants/keys.dart`.
- `lib/src/theme/`: Material 3 light/dark theme with `BaseColorExtension` and typography extension; `context.colors` / `context.text`.
- `lib/src/shared/components/`: `AppLoader`, `AppError`, `AppEmptyWidget`, `AppConfirmation`, snack bar helper.
- `lib/src/routes/app_router.dart` with `keepAlive` `appRouterProvider`; `SplashRoute` → `HomeRoute` `TabsRouter` with placeholder Dashboard, Leads, Calls, Follow-ups, Settings pages.
- `MODULE.md` for each folder created.

**Shorebird + restart after patch**
- `shorebird init` under the personal Shorebird account → commit `shorebird.yaml`.
- Release signing: create a keystore, `android/key.properties` (git-ignored), signing config in Gradle. Back up the keystore outside the repo.
- Add `INTERNET` to the main manifest (Shorebird only).
- `src/update/`: `shorebirdProvider`, `Patch` notifier (`hidden → available → downloading → readyToRestart`), `PatchBanner` above the home bottom navigation, `restart()` using `RestartMode.process`.
- Settings placeholder shows version and patch status.

**Device POCs**
- Tiny share-intent receiver: Google Phone shares one recording, the Kotlin bridge copies the `content://` URI into app cache, and a debug screen shows file name, MIME type, size, and cache path.
- Separately investigate whether `READ_CALL_LOG` can be held with the sideload install method on the realme device. Document the result; do not build a bypass.

### Exit criteria

- `shorebird release android --artifact apk --flutter-version=3.38.3` produces a release APK that installs and launches on the realme 11 Pro+ 5G.
- A test patch (e.g. a visible text change) is published with `shorebird patch android`; the banner appears, **Update** downloads it, **Restart now** relaunches into the patched code, and the banner does not come back.
- Google Phone can share a recording to the app and the bridge copies it into cache (cold and warm start).
- Call-log permission outcome is documented. If blocked, continue with manual call logs.
- Codegen, format, analyze, and tests pass.

**Ships as:** first release (`1.0.0+1`).

## Milestone 1 — Foundation and SQLite

### Deliverables

- `core/database/`: open/close lifecycle, schema version 1, migration framework, `onDowngrade` guard, foreign keys on.
- `keepAlive` `appDatabaseProvider`; `startupProvider` opens the DB before `HomeRoute`.
- Typed models and repositories in each feature's `data/` for leads, call logs, follow-ups, recording metadata, and settings.
- Repository and migration tests on a temporary database.

### Exit criteria

- Database survives app restart and patch restart.
- Foreign keys and indexes verified; CRUD tests pass.
- Loading, empty, and error states exist.

**Ships as:** new release. It adds `sqflite` (a plugin with native code) and creates the first schema; every later schema change also needs a release (see `DATABASE_SCHEMA.md` §6a). `path_provider` is deferred to Milestone 4, where recordings need the documents directory.

**Status:** code done — phone normaliser, all five repositories, persisted theme, 85 automated tests. Device check: `DEVICE_TEST_CHECKLIST.md` §F.

## Milestone 2 — Lead management

### Deliverables

- Leads list with search and filters (`ListView.builder`).
- Add/edit lead form with validation; lead detail route.
- Status and temperature controls.
- Dialer via `url_launcher` `tel:`; WhatsApp `wa.me` link when safe.
- Manual call log creation and summary; lead timeline.

### Exit criteria

- Leads can be managed offline; tap-to-call opens the dialer; manual calls appear in the timeline.

**Ships as:** release if `url_launcher` is new to the build (native plugin), otherwise patch.

## Milestone 3 — XLSX and CSV import

### Deliverables

- File picker, XLSX and CSV parsers (off the UI thread).
- Column mapping with aliases; validation and duplicate preview.
- Transactional bulk insert; result summary.

### Exit criteria

- Representative XLSX and CSV files import correctly; invalid rows and duplicates are reported; cancelling leaves no partial insert; works offline.

**Ships as:** release (`file_picker` has native code). `excel`/`csv` alone would be patchable.

## Milestone 4 — Google Phone recording import

### Deliverables

- Production version of the `ACTION_SEND` / `ACTION_SEND_MULTIPLE` Kotlin bridge (cold/warm start, queued shares).
- Import confirmation screen; lead selection and optional call-log link.
- Permanent private storage; SHA-256 duplicate detection.
- Playback (`just_audio`) and deletion; file-picker fallback.
- Restart button disabled while an import is running.

### Exit criteria

- A real Google Phone recording is shared in, copied to private storage, and still plays after the source is gone.
- Wrong-client attachment is prevented by confirmation; duplicates are detected; failed imports never silently lose the file.

**Ships as:** release (Kotlin + `just_audio`).

## Milestone 5 — Optional Android call-history sync

Only if the Milestone 0 POC passed.

- `CallHistoryDataSource` adapter, availability UI, foreground sync on resume and **Sync Now**, overlap window, dedupe, ambiguous-match resolution.
- Exit: real call entries read repeatedly without duplicates; restricted state handled; manual calls still work.

**Ships as:** release (`call_log` plugin + manifest permission). If the POC failed, mark this milestone blocked.

## Milestone 6 — Follow-ups and reminders

- Create/edit/reschedule/complete/cancel; Today, Overdue, Upcoming, Completed views.
- Local notifications with IDs stored in SQLite; notification permission only when reminders are enabled.
- Exit: follow-ups persist; completing/cancelling cancels the notification; permission denial doesn't break follow-ups.

**Ships as:** release (`flutter_local_notifications` + manifest receivers).

## Milestone 7 — Dashboard, backup, and hardening

- Dashboard metrics and recent activity from SQLite.
- Local backup/export of database and recordings; restore with validation.
- Storage usage view and safe deletion; error-state polish and accessibility pass.
- Device test checklist, including a patch + restart run.
- Exit: offline core flow works; backup includes DB and recordings; restore passes on a clean install; format/analyze/tests pass; device smoke tests pass.

**Ships as:** patch if no new native plugins are added; otherwise release.

## Per-milestone checklist

- [ ] Inspect existing files before editing.
- [ ] Implement only the current milestone.
- [ ] `fvm dart run build_runner build --delete-conflicting-outputs`.
- [ ] Add/update tests.
- [ ] `fvm dart format .`, `fvm flutter analyze`, `fvm flutter test`.
- [ ] Add/update the feature's `MODULE.md`.
- [ ] Decide **patch or release** (see `BUILD_AND_RELEASE.md`) and ship it.
- [ ] Document manual test steps and limitations.
- [ ] Summarise files changed, commands run, results, and next milestone.
