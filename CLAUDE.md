# Claude Code Instructions — Lead Tracker

You are implementing a small, personal, Android-only Flutter application. Read `README.md`, `PROJECT_DESCRIPTION.md`, `STACK.md`, `ARCHITECTURE.md`, `DATABASE_SCHEMA.md`, `ANDROID_INTEGRATIONS.md`, and `IMPLEMENTATION_PLAN.md` before coding.

## 1. Product boundaries

- This is a single-user personal app, not a commercial CRM.
- Android only for the MVP.
- Flutter UI, SQLite database, private on-device file storage.
- No backend, login, cloud sync, Firebase, Supabase, Appwrite, analytics, ads, paid SDKs, AI APIs, or network-dependent core workflow.
- XLSX and CSV import are required.
- Google Phone handles cellular call recording. Lead Tracker only receives a user-shared recording and imports it.
- Do not implement microphone capture, cellular call audio capture, call interception, root-only access, or a workaround that bypasses Android security.

## 2. Critical Android permission rules

`READ_CALL_LOG` is a hard-restricted Android permission. It cannot be held unless the installer on record allowlists it. Google Play further restricts Call Log permissions to apps actively registered as the default Phone or Assistant handler, subject to the published policy.

Therefore:

1. Do not assume a runtime permission dialog is sufficient.
2. Do not make call-log sync a dependency for app usability.
3. Build a Phase 0 proof-of-concept on the actual realme 11 Pro+ 5G before integrating call-log sync into the app.
4. Keep the integration behind an interface such as `CallHistoryDataSource` and a feature-availability state.
5. Do not add call-log permissions to the final manifest unless the POC has established a permitted way to grant them on the target device and the user explicitly wants the feature.
6. Never request `WRITE_CALL_LOG`, `PROCESS_OUTGOING_CALLS`, `READ_PHONE_NUMBERS`, or contacts permissions unless a separately documented feature proves it needs them.
7. If unavailable, expose manual call logging and recording attachment as the supported path.

Do not tell the user that call history will automatically sync unless the physical-device test passes.

## 3. Google Phone recording integration

- Google Phone is the user's installed Phone app.
- Google Phone's automatic recording is configured by the user in Google Phone settings; Lead Tracker cannot toggle it.
- Lead Tracker must be a target for Android `ACTION_SEND` and optionally `ACTION_SEND_MULTIPLE` for `audio/*` files.
- Implement the Android receiving activity/intent handling carefully. Support both a cold start (`onCreate`) and an already-running app (`onNewIntent`).
- The incoming shared file is commonly a `content://` URI with a temporary URI grant. Open it through Android `ContentResolver` and copy it into app-private cache/storage while the grant is valid. Do not store the external URI as the permanent file path.
- Stream-copy files; do not load large recordings fully into memory.
- Pass the copied internal path, display name, MIME type, and size to Flutter using a documented MethodChannel/EventChannel bridge. Handle both initial and subsequent intents without losing events.
- Flutter then moves/copies the file into the permanent recordings directory and inserts metadata in SQLite. If persistence fails, retain a recoverable temp file and show an actionable error.
- Always ask the user to confirm the lead. A suggested match is not a confirmed match.
- Provide an in-app file-picker fallback if Google Phone's share payload or MIME type differs from expectations.
- Do not read Google Phone's private directories or depend on a manufacturer-specific folder path.
- Do not claim import is automatic after a call. Sharing from Google Phone is a user action.

## 4. Architecture and code quality

- Use feature-first Clean Architecture, but keep it pragmatic. Do not introduce unnecessary abstraction layers or code generation.
- Widgets must not run SQL or contain import, matching, file-copy, or permission business logic.
- Use Riverpod for dependency injection and UI state.
- Repositories own persistence operations.
- Services own file import, phone launching, notifications, share payload processing, and optional call-history sync.
- Keep database access behind repositories/data sources.
- Use immutable models where practical and explicit `fromMap`/`toMap` mapping.
- Use enums or typed value objects for lead status, temperature, call type, call outcome, and follow-up status. Persist stable string values in SQLite.
- Use UTC Unix milliseconds for persisted timestamps; format local time only in the UI.
- Normalise phone numbers in one tested utility. Preserve the original number as entered/imported. Use India (`IN`, `+91`) as the initial default region but make the default country code configurable; do not destroy international prefixes.
- SQLite schema starts at version 1 and all future changes use migrations.
- Use transactions for imports and database updates that span multiple rows.
- Use partial unique indexes where appropriate; SQLite permits multiple NULL values in a unique index.
- Use parameterised SQL and never concatenate user input into SQL.
- Avoid storing audio blobs in SQLite. Store private file paths and metadata only.

## 5. Dependency discipline

- Use `STACK.md` as the dependency baseline.
- Before adding a dependency, check current pub.dev docs, platform support, license, latest stable version, minimum Flutter/Dart SDK, and maintenance activity.
- Do not blindly copy old snippets for fast-moving packages such as `file_picker` or `flutter_local_notifications`; inspect the installed version's README/changelog and compile against its actual API.
- Run `flutter pub get`, `flutter analyze`, and tests after dependency changes.
- Do not add a dependency for a feature that can be handled cleanly with Flutter SDK or a small, well-contained Android Kotlin bridge.
- Commit `pubspec.lock` for this application.

## 6. UI requirements

Keep the interface simple, fast, and mobile-first. Primary sections:

1. Dashboard
2. Leads
3. Calls
4. Follow-ups
5. Settings

Lead detail is a pushed route, not an extra bottom tab. Recording playback and import confirmation can be dedicated routes/dialogs.

- Use Material 3.
- Use consistent spacing, typography, and empty/error/loading states.
- Search and filters must work on device data.
- Do not create decorative charts or unnecessary screens.
- Ensure forms validate phone and required name fields.
- Confirm destructive actions such as deleting a lead or recording.

## 7. Data integrity and privacy

- Keep all data local. Do not add internet permission unless an explicitly approved future requirement needs it.
- Do not transmit contacts, call logs, notes, or recordings to any service.
- Never auto-send WhatsApp messages, emails, or recordings.
- Ask for and respect applicable consent/notice requirements for recording conversations. Google Phone may announce recording to participants; the app must not suppress or bypass that announcement.
- Recording imports must be user initiated.
- Store recordings in the app-private documents directory, in per-lead subdirectories using generated filenames. Do not trust incoming filenames as filesystem paths.
- Compute SHA-256 and file size for deduplication/integrity checks.
- Do not delete a source recording from Google Phone.
- If a lead with recordings is deleted, use an explicit confirmation and a documented retention decision. Prefer soft deletion or block deletion until recordings are reassigned/deleted; never silently orphan audio.
- Do not log full phone numbers, call notes, file contents, or recording paths in production logs.

## 8. Testing rules

For every feature:
- add unit tests for business logic;
- add repository/database tests using a temporary test database;
- add widget tests for key success/error/empty states where practical;
- run `dart format .`;
- run `flutter analyze`;
- run `flutter test`.

For Android integrations, add a reproducible manual test checklist. Do not mark an Android integration complete from a mocked test alone.

## 9. Implementation workflow

- Follow `IMPLEMENTATION_PLAN.md` in order.
- Work one milestone at a time; do not scaffold every feature in one enormous change.
- Before changing files, inspect the current project and preserve existing working configuration.
- After each milestone, summarise files changed, commands run, tests passed, unresolved risks, and next milestone.
- Do not invent API fields, permissions, or package methods. Inspect package source/docs when uncertain.
- If a platform restriction blocks a feature, stop and report it; implement the documented fallback rather than bypassing the restriction.

## 10. Definition of done

A milestone is done only when:
- code compiles;
- formatting and analysis pass;
- relevant automated tests pass;
- manual device steps are documented for platform integrations; and
- no unrelated feature or dependency has been added.
