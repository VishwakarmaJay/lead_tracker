# calls

**Path:** `lib/src/calls/` · **Layer:** feature · **Status:** data layer done (Milestone 1); UI in Milestone 2, system sync in Milestone 5 (if the POC passes)

## Data

- `data/models/call_log.dart` — `CallLog`, `CallLogDraft`, enums `CallSource`, `CallType`, `CallDisposition` (user-chosen, never inferred).
- `data/call_log_repository.dart` — `CallLogRepository` / `callLogRepositoryProvider`: `createCallLog`, `getCallLogById`, `updateCallLog`, `linkToLead` (or unlink with null), `deleteCallLog`, `listForLead`, `listRecent` (newest first).

The partial unique index allows any number of manual logs but rejects a repeated `(android_call_log, source_record_id)` — "This record already exists."

## Tests

`test/calls/call_log_repository_test.dart`
