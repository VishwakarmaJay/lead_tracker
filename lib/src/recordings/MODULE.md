# recordings

**Path:** `lib/src/recordings/` · **Layer:** feature · **Status:** Milestone 4 code done

Google Phone call recordings (shared in) and audio files (picked), attached to a lead, stored privately, played back.

## Flow

1. **Share in** — Google Phone → Share → Lead Tracker. The Kotlin bridge copies the file into a durable inbox (`filesDir/shared_imports`) and the home shell opens **Shared recordings**.
2. **Shared recordings** (`SharedInboxRoute`, `ui/shared_inbox_page.dart`) — every recording still waiting, even after the app was closed. **Save to a lead** or **Discard** (the Google Phone original is never touched). Failed shares show their reason and can be dismissed. Empty state offers **Pick an audio file**.
3. **Save recording** (`RecordingImportRoute(recording, initialLeadId?)`, `ui/recording_import_page.dart`) — listen to it, choose the lead (picker; leads called in the last 24 h as shortcuts — never guessed from the file name), optionally link one of that lead's calls, add notes, **Save to <lead>**. A duplicate opens "Already saved" → Open it / Discard this copy.
4. **Lead timeline** — recordings appear with the calls (`RecordingTile`); a call with a recording shows a waveform icon.
5. **Player** (`RecordingPlayerRoute(recordingId)` `/recordings/:id`, `ui/recording_player_page.dart`) — play/pause, seek, 1×/1.5×/2×, lead, saved date, original name, notes, linked call (change it), delete.

Fallback: lead detail → **Add recording** picks an audio file and opens step 3 with that lead chosen.

## Import rules (`services/recording_import_service.dart`)

- Exists, not empty, ≤ 200 MB, supported format (`data/audio_formats.dart`: MIME first, then extension; stored extension comes only from that table).
- SHA-256 streamed in a background isolate; an already-imported checksum returns `RecordingAlreadyImported` and saves nothing.
- `AudioProbe` (just_audio) reads the duration; a file the phone can't play is still saved, flagged `playable: false`.
- **Copies** to `recordings/lead_<id>/<random>.<ext>` (via `.part` + rename), then inserts the row. If the insert fails the copy is removed and the original stays, so the user can retry.
- The service never deletes the original. `RecordingImportController` removes the inbox copy (or the picker's temp copy) only after a successful import. Runs inside `busyOperationsProvider.track`, so **Restart now** waits.
- Delete: row first, then file (a leftover file is harmless; storage cleanup is Milestone 7).

## Providers

- `sharedInboxProvider` (keepAlive) — `pull()` merges new shares (`takePending`) with what is on disk (`listCached`); `discard()`. `mergeInbox()` is the pure merge.
- `recordingImportControllerProvider` — `save(...)`, `discardSource(...)`.
- `recordingDetailProvider(id)` — `updateNotes`, `linkToCall`, `saveDuration` (only if unknown), `delete`.
- `recordingFileProvider(relativePath)` — absolute `File`.
- `recordingImportServiceProvider`, `recordingStorageProvider`, `audioProbeProvider` — overridable in tests.

## Public for other features

- `ui/components/recording_tile.dart` — `RecordingTile` (lead timeline).
- `ui/components/recording_player.dart` — `RecordingPlayer(path, onDuration)`, `formatClock`.
- `ui/shared_inbox_page.dart` — `pickAudioAndImport(context, ref, leadId:)` (lead detail's Add recording).

## Data

- `data/models/call_recording.dart` — `CallRecording`, `CallRecordingDraft`, `RecordingImportSource`.
- `data/models/pending_recording.dart` — `PendingRecording` (path, origin, name, MIME, size, inbox item).
- `data/call_recording_repository.dart` — create (SHA-256 unique), get, `findBySha256`, `listForLead`, `linkToCallLog`, `updateNotes`, `updateDuration`, `deleteRecordingRow`.
- `data/recording_storage.dart` — `RecordingStorage` (`resolve`, `copyIn`, `delete`), `sha256OfFile`.

## Native side

`android/app/src/main/kotlin/com/vishwakarmajay/leadtracker/ShareBridge.kt` — see ANDROID_INTEGRATIONS.md §3. Methods: `takePending`, `listCached`, `deleteCached`; event channel signals new shares.

## Tests

`test/recordings/` — formats, import service (copy, checksum, duplicates, unplayable, bad files, failed insert keeps the original, delete), inbox merge and channel calls, controller (inbox copy cleared only on success), player-screen actions. `test/leads/timeline_test.dart` — call/recording ordering.
