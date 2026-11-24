# leads

**Path:** `lib/src/leads/` · **Layer:** feature · **Status:** data layer done (Milestone 1); UI in Milestone 2

## Data

- `data/models/lead.dart` — `Lead`, `LeadDraft`, `LeadQuery` (value-equal), enums `LeadStatus` (`newLead` ↔ `'new'`, …) and `LeadTemperature`.
- `data/lead_repository.dart` — `LeadRepository` / `leadRepositoryProvider`:
  - `searchLeads(LeadQuery)` — text matches name, company, email, phone, normalised phone (`%`/`_` escaped); filters by status/temperature; sorted by name (case-insensitive); optional paging.
  - `getLeadById`, `createLead`, `createLeads` (one transaction), `updateLead`.
  - `deleteLead` = soft delete (`deleted_at`), `restoreLead`.
  - `findByNormalizedPhone` → **list** (several leads may share a number).

Failures surface as `AppException` (e.g. "This lead no longer exists."). The caller computes `phoneNormalized` with `PhoneNormalizer`.

## Tests

`test/leads/lead_repository_test.dart`
