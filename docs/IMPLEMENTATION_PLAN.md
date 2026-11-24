# Implementation Plan — Lead Tracker

Build one milestone at a time. Do not generate the entire application in one pass.

## Milestone 0 — Project bootstrap and device POCs

### Deliverables

- Create Android-only Flutter project.
- Confirm Flutter/Dart/Android toolchain with `flutter doctor -v`.
- Add baseline dependencies and commit `pubspec.lock`.
- Create Material 3 theme and bottom navigation shell.
- Build a tiny Android share-intent proof-of-concept to receive one Google Phone audio recording.
- Separately investigate whether `READ_CALL_LOG` can be held by the intended install method on the realme device.

### Exit criteria

- Debug APK installs and launches on realme 11 Pro+ 5G.
- Google Phone can share a test recording to the app and the native bridge can copy the content URI into app cache.
- Call-log permission outcome is documented. If blocked, record the blocker and continue with manual call logs; do not block the project.

## Milestone 1 — Foundation and SQLite

### Deliverables

- Feature-first folder structure.
- Riverpod setup and provider wiring.
- SQLite database open/close lifecycle.
- Version-1 schema and migration framework.
- Typed models and repositories for leads, call logs, follow-ups, and recording metadata.
- Database/repository tests.

### Exit criteria

- Database survives app restart.
- Foreign keys and indexes are verified.
- CRUD repository tests pass.
- UI has loading, empty, and error states.

## Milestone 2 — Lead management

### Deliverables

- Leads list.
- Search and filters.
- Add/edit lead form.
- Lead detail screen.
- Status and temperature controls.
- Native dialer action with `tel:`.
- Manual call log creation and call summary.

### Exit criteria

- User can create and manage leads without internet.
- Tap-to-call opens the native dialer.
- A manual call entry appears in the lead timeline.

## Milestone 3 — XLSX and CSV import

### Deliverables

- File picker integration.
- XLSX and CSV parsers.
- Column mapping/alias handling.
- Validation and duplicate preview.
- Transactional bulk insert.
- Import result summary.

### Exit criteria

- A representative XLSX and CSV file import correctly.
- Invalid rows and duplicate candidates are reported.
- Cancellation causes no partial insert.
- Import works offline.

## Milestone 4 — Google Phone recording import

### Deliverables

- ACTION_SEND and ACTION_SEND_MULTIPLE audio intent support.
- Kotlin bridge for `content://` stream copying.
- Cold-start and warm-start share handling.
- Flutter import confirmation screen.
- Lead selection and optional call-log linking.
- Private permanent file storage.
- SHA-256 duplicate detection.
- Recording playback and deletion.
- Manual audio file-picker fallback.

### Exit criteria

- Real Google Phone recording can be shared into the app on the realme device.
- File is copied into app-private storage and remains playable after the share source is no longer used.
- Wrong-client attachment is prevented by explicit user confirmation.
- Duplicate import is detected.
- Failed imports do not silently lose the file.

## Milestone 5 — Optional Android call-history sync

Only implement if Milestone 0 POC passed.

### Deliverables if available

- `CallHistoryDataSource` adapter.
- Permission/availability UI.
- Foreground sync on app resume and manual Sync Now.
- Recent-window sync with overlap.
- System-record deduplication.
- Phone number matching and ambiguity resolution.

### Exit criteria

- Real device call entries are read repeatedly without duplicate insertion.
- Permission-denied/restricted state is handled gracefully.
- Manual calls remain supported.

If POC fails, mark this milestone blocked/not supported and retain manual call logging.

## Milestone 6 — Follow-ups and reminders

### Deliverables

- Create/edit/reschedule/complete/cancel follow-ups.
- Today, overdue, upcoming, and completed views.
- Local notifications with notification IDs stored in SQLite.
- Notification permission handling.

### Exit criteria

- Follow-ups persist across restart.
- Completing/cancelling a follow-up cancels its scheduled notification.
- Permission denial does not break follow-up management.

## Milestone 7 — Dashboard, backup, and hardening

### Deliverables

- Dashboard metrics and recent activity.
- Local export/backup of database and recording files.
- Restore flow with validation and conflict strategy.
- Storage usage view and safe deletion.
- Error-state polish and accessibility pass.
- Device test checklist.

### Exit criteria

- App's core flow works offline.
- Database and recording files are both included in backup.
- Restore test passes on a clean app install.
- `dart format .`, `flutter analyze`, and `flutter test` pass.
- Physical-device smoke tests pass.

## Per-milestone engineering checklist

- [ ] Inspect existing project files before editing.
- [ ] Implement only the current milestone.
- [ ] Add/update tests.
- [ ] Run `dart format .`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Build Android debug APK where relevant.
- [ ] Document manual test steps and limitations.
- [ ] Summarise files changed, commands run, results, and next milestone.
