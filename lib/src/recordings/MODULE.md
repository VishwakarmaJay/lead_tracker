# recordings

**Path:** `lib/src/recordings/` · **Layer:** feature

## Data (Milestone 1)

- `data/models/call_recording.dart` — `CallRecording`, `CallRecordingDraft`, `RecordingImportSource`.
- `data/call_recording_repository.dart` — `CallRecordingRepository` / `callRecordingRepositoryProvider`: `createRecording` (SHA-256 unique → "This record already exists."), `getRecordingById`, `findBySha256`, `listForLead`, `linkToCallLog`, `updateNotes`, `deleteRecordingRow`. Metadata only; files are handled by the Milestone 4 import service.
- A lead with recordings can't be removed (`ON DELETE RESTRICT`); deleting a call keeps its recordings (`SET NULL`).
- Tests: `test/recordings/call_recording_repository_test.dart`.

## Milestone 0 (proof of concept)

- `sharedInboxProvider` (keepAlive — owns the share-event subscription for the session): holds `SharedFilePayload`s taken from the Kotlin queue. `pull()` takes queued shares; `discard()` deletes the cached copy (Kotlin refuses paths outside `cache/shared_imports/`).
- `SharedInboxPage` (`SharedInboxRoute`): one card per share with name, MIME type, size, received time, shared text, cache path, or the error. Discard asks for confirmation and never touches the original in Google Phone.

## Native side

`android/app/src/main/kotlin/com/vishwakarmajay/leadtracker/ShareBridge.kt` (`ShareIntake` + `ShareBridge`), intent filters in `AndroidManifest.xml`:

- Handles `ACTION_SEND` / `ACTION_SEND_MULTIPLE` with `audio/*` on cold start (`onCreate`, skipping re-delivered intents) and warm start (`onNewIntent`).
- Stream-copies each `content://` URI on a background thread into `cache/shared_imports/<uuid>.<ext>`; extension from MIME type only; 200 MB cap; free-space check.
- Every share yields a payload; failures carry an `error` string instead of being dropped.

## Milestone 4 replaces

Discard-only inbox → real import (lead confirmation, permanent storage, SHA-256, playback) and adds stale-cache cleanup.
