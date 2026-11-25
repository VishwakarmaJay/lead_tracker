# leads

**Path:** `lib/src/leads/` · **Layer:** feature · **Status:** Milestone 2 done

## Screens

| Route | Page | What |
| --- | --- | --- |
| `LeadsRoute` (tab) | `ui/leads_page.dart` | Search (debounced), status/temperature filter chips, list, **Add lead** |
| `LeadDetailRoute(leadId)` `/leads/:id` | `ui/lead_detail_page.dart` | Header (status dropdown, temperature chips), Call / WhatsApp / Log call, contact info, Activity timeline, delete with Undo |
| `LeadFormRoute(leadId?)` | `ui/lead_form_page.dart` | Add or edit. Live phone hint, warns on unrecognised or duplicate numbers, discard prompt |

Sections: `ui/sections/lead_{header,actions,info,timeline}_section.dart`.

## Providers

- `leadListFilterProvider` (`LeadQuery`) + `leadListProvider` — the Leads tab.
- `leadSearchProvider(text)` — the lead picker.
- `leadDetailProvider(leadId)` (`LeadDetail`) — `setStatus`, `setTemperature` (optimistic), `delete`, `restore`.
- `leadTimelineProvider(leadId)` (`LeadTimeline`) — `List<TimelineEntry>`: `TimelineCall` and `TimelineRecording`, newest first; a linked recording sits just above its call (`buildTimeline`). `deleteCall`.

The detail screen's actions include **Add recording** (file-picker fallback → recording import with this lead chosen).
- `leadEditorProvider` (`LeadEditor`) — `save`, `findDuplicates`, `isPhoneRecognised`.
- `lead_refresh.dart` — `ref.refreshLeadViews(leadId:)` after any write.
- Validation: `validateLeadName/Phone/Email`, `leadDraftFromInput` in `providers/lead_form_provider.dart`.

## Public for other features

- `ui/components/lead_picker_sheet.dart` — `showLeadPicker(context)` → `Lead?`.
- `ui/components/lead_labels.dart` — `status.label`, `temperature.label/color/icon`, `LeadAvatar`, `LabelPill`.

## Data

- `data/models/lead.dart` — `Lead`, `LeadDraft`, `LeadQuery`, `LeadStatus`, `LeadTemperature`.
- `data/lead_repository.dart` — search, get, create (one or many, one transaction), update, soft delete/restore, `findByNormalizedPhone` → list, `activeNamesByNormalizedPhone` (import duplicate check).

The Leads tab links to the import wizard (`ImportRoute`) from the app bar and the empty state.

## Depends on

`calls` (public: `showLogCallSheet`, `CallLogTile`, `pendingCallTrackerProvider`), `core/instances/phone_launcher.dart`, `src/shared/providers/phone_normalizer_provider.dart`.

## Tests

`test/leads/` — repository, form/validators/editor, list/detail providers, widgets.
