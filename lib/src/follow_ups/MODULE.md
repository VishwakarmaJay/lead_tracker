# follow_ups

**Path:** `lib/src/follow_ups/` · **Layer:** feature · **Status:** data layer done (Milestone 1); UI + reminders in Milestone 6

## Data

- `data/models/follow_up.dart` — `FollowUp` (`isOverdueAt(now)`), `FollowUpDraft`, `FollowUpStatus`.
- `data/follow_up_repository.dart` — `FollowUpRepository` / `followUpRepositoryProvider`: `createFollowUp`, `getFollowUpById`, `updateFollowUp`, `reschedule`, `complete`, `cancel` (all only while pending), `setNotificationId`, `listForLead`, `listPending({dueBefore, limit})` (soonest first), `listClosed(status)`.

Lists hide follow-ups of soft-deleted leads. Removing a lead row cascades to its follow-ups.

## Tests

`test/follow_ups/follow_up_repository_test.dart`
