# calls

**Path:** `lib/src/calls/` · **Layer:** feature · **Status:** Milestone 2 done (manual calls); system sync is Milestone 5 if the POC passes

## Screens

`CallsPage` (`CallsRoute`, tab) — calls logged in Lead Tracker, newest first, with the lead's name (tap opens the lead). **Log call** → lead picker → log sheet. States clearly that it isn't the phone's call history.

## Providers

- `recentCallsProvider` — `listRecentWithLeads()`.
- `leadCallsProvider(leadId)` — one lead's calls, for linking a recording to a call.
- `callLogEditorProvider` (`CallLogEditor`) — `save(CallLogInput, existing:)`: manual call (copies the lead's phone/name onto the call), edit, optional lead temperature change.
- `pendingCallTrackerProvider` (keepAlive, `PendingCallTracker`) — `dial(lead)` opens the dialer via `PhoneLauncher` and remembers the call; the home shell calls `markLeftApp()` on hide and `takeOnReturn()` on resume to open the Log call sheet (only if the app really went to the background, within 3 hours).

## Public for other features

- `ui/components/log_call_sheet.dart` — `showLogCallSheet(context, leadId:, leadName:, currentTemperature:, existing:, calledAt:)` → `bool` saved.
- `ui/components/call_log_tile.dart` — `CallLogTile`.
- `ui/components/call_labels.dart` — `callType.label/icon/color`, `disposition.label`.

## Data

- `data/models/call_log.dart` — `CallLog`, `CallLogDraft`, `CallLogWithLead`, `CallSource`, `CallType`, `CallDisposition` (user-chosen, never inferred).
- `data/call_log_repository.dart` — create, get, update, link/unlink lead, delete, `listForLead`, `listRecent`, `listRecentWithLeads`.

## Tests

`test/calls/` — repository, editor, pending-call tracker.
