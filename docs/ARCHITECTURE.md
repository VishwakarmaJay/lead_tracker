# Architecture — Lead Tracker

## 1. Architectural style

Use feature-first Clean Architecture with a small number of layers. Avoid over-engineering a single-user offline app.

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
├── core/
│   ├── database/
│   │   ├── app_database.dart
│   │   └── migrations/
│   ├── files/
│   ├── notifications/
│   ├── phone/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── dashboard/
│   │   ├── data/
│   │   └── presentation/
│   ├── leads/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── call_history/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── services/
│   │   └── presentation/
│   ├── recordings/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── services/
│   │   └── presentation/
│   ├── follow_ups/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── imports/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── providers/
```

A feature can be simplified if it has no meaningful domain logic. Do not create empty folders or interfaces for every class.

## 2. Dependency direction

```text
Presentation (screens/widgets)
          |
          v
Riverpod controllers/providers
          |
          v
Repositories / application services
          |
          v
SQLite data source / filesystem / Android bridge
```

Rules:

- Widgets do not import `sqflite` or execute SQL.
- Widgets do not copy files or parse Excel workbooks.
- Repositories return typed models, not raw SQLite maps.
- Services coordinate workflows such as import, recording attachment, and notification scheduling.
- Android-specific behavior is isolated behind interfaces.

## 3. Core interfaces

Recommended interfaces (names may be adapted, behaviour must remain):

```dart
abstract interface class LeadRepository {
  Future<List<Lead>> searchLeads(LeadQuery query);
  Future<Lead?> getLeadById(int id);
  Future<int> createLead(LeadDraft draft);
  Future<void> updateLead(Lead lead);
  Future<void> deleteLead(int id);
  Future<Lead?> findByNormalizedPhone(String normalizedPhone);
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

`CallHistoryDataSource` can report unavailable without throwing through the entire app. A manual call-log repository path must always remain available.

## 4. Phone number handling

- Preserve the user's original phone string.
- Store a separate normalized value for lookup/deduplication.
- Initial default region is India (`IN`) and default country calling code is `+91`.
- Do not strip a leading `+` and then assume every number is Indian.
- Test examples such as `9876543210`, `+91 98765 43210`, `09876543210`, and numbers with spaces, hyphens, and parentheses.
- Invalid numbers should still be importable if the user explicitly chooses to keep them, but should be flagged and excluded from automatic matching.

## 5. Excel/CSV import pipeline

1. Pick a file and copy it to a temporary app cache location if required by the picker API.
2. Detect format by extension/MIME and validate supported extension.
3. Parse header row and show a column-mapping screen.
4. Require mapped `name` and `phone` columns.
5. Convert rows to `LeadImportCandidate` objects.
6. Trim fields, preserve original phone, normalize where possible.
7. Detect duplicates inside the selected file and against existing leads.
8. Show counts: valid, invalid, duplicate, and skipped.
9. User confirms import strategy (skip duplicate by default; do not overwrite existing lead data silently).
10. Insert selected rows using one SQLite transaction/batches.
11. Show an import result screen.

Do not assume header names are identical to the template. Support common aliases such as `Name`, `Full Name`, `Phone`, `Mobile`, `Contact`, `Company`, `Email`, `Website`.

## 6. Recording import pipeline

1. Android receives `ACTION_SEND` or `ACTION_SEND_MULTIPLE` with an audio MIME type.
2. Kotlin obtains `Intent.EXTRA_STREAM` or `Intent.EXTRA_STREAM` list/clip data and checks the granted URI permissions.
3. Kotlin copies each `content://` URI to an internal cache file using `ContentResolver.openInputStream` and buffered streaming.
4. Kotlin sends a payload to Flutter: cache path, display name, MIME type, byte size, and optional shared text. Do not assume caller number or call timestamp is included.
5. Flutter validates the copied file and computes SHA-256.
6. UI asks the user to choose a lead. Offer possible matching leads only when there is grounded metadata; do not guess based only on filename.
7. User may optionally link an existing local call log.
8. Copy/move file to `ApplicationDocumentsDirectory/recordings/lead_<id>/<generated-id>.<safe-extension>`.
9. Insert metadata row in a SQLite transaction.
10. If DB insert fails, keep a recoverable temp file and display Retry/Cleanup actions.
11. If the same SHA-256 already exists, offer to cancel or open the existing recording rather than create a duplicate.

A recording can be linked to a lead even if no call metadata exists. The audio file remains a separate file, not a SQLite BLOB.

## 7. Dashboard queries

All dashboard values should be derived from SQLite:

- total leads;
- calls logged today;
- hot leads;
- pending follow-ups due today or overdue;
- latest five call records;
- next five pending follow-ups.

Avoid caching stale counters unless there is a measured performance reason.

## 8. Failure handling

Provide explicit states for:

- database open/migration error;
- file picker cancellation;
- unsupported/invalid file;
- malformed XLSX/CSV;
- invalid rows;
- duplicate rows;
- insufficient storage;
- shared URI permission expired;
- MIME type not recognised;
- audio copy failure;
- checksum duplicate;
- audio decode/playback failure;
- notification permission denied;
- call-log permission unavailable or blocked.

Do not silently ignore exceptions. Do not show raw exception traces in the UI; log safe diagnostic details without sensitive user content.
