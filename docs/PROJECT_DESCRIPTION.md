# Project Description — Lead Tracker

## 1. Product summary

**Lead Tracker** is a private, single-user Android application for organising freelance outreach. The user imports a spreadsheet of prospective clients, calls them using the phone's native dialer, records what happened, classifies the lead, attaches call recordings shared from Google Phone, and schedules follow-ups.

The app is intentionally small. It is not a multi-user CRM or a SaaS product.

## 2. Problem statement

When contacting potential freelance clients, it is easy to forget:

- who was called;
- what was discussed;
- whether the client showed interest;
- what budget or requirements were mentioned;
- whether a portfolio or proposal was promised; and
- when to follow up.

Lead Tracker keeps this information in one local client history.

## 3. Target user and platform

- Primary user: the app owner, using it for personal freelance prospecting.
- Initial platform: Android only.
- Reference device for integration testing: realme 11 Pro+ 5G.
- Phone app: Google Phone, confirmed by the user.
- Call recording source: Google Phone's built-in call recording and its Android Share action.
- Storage: local SQLite database and private app file storage.

Do not build iOS or web support in this MVP. Keep business logic reasonably platform-independent, but Android is the only supported delivery target.

## 4. Core user journey

1. The user selects an Excel or CSV file.
2. The app previews rows, validates required fields, identifies likely duplicates, and imports selected rows.
3. The user opens a lead and taps Call. The native dialer opens; Lead Tracker does not place or record the call itself.
4. The user returns to Lead Tracker and adds a brief summary, outcome, temperature, and optional follow-up.
5. If Google Phone recorded the call, the user opens that recording in Google Phone and shares it to Lead Tracker.
6. Lead Tracker copies the shared audio file to its private storage, suggests a lead match where possible, and asks the user to confirm the lead and call association.
7. The recording appears in the lead's timeline and can be played later.
8. The dashboard and follow-up screen show what needs attention.

## 5. MVP screens

### 5.1 Dashboard

Show only useful personal-work metrics:

- total leads;
- calls logged today;
- hot leads;
- follow-ups due today or overdue;
- latest calls; and
- next follow-ups.

All figures must come from SQLite. Do not add elaborate charts.

### 5.2 Leads

- List leads with name, company, phone, status, and temperature.
- Search by name, company, email, and phone.
- Filter by status and temperature.
- Add and edit a lead.
- Import XLSX/CSV.

### 5.3 Lead detail

- Contact information and native call action.
- WhatsApp shortcut using a `https://wa.me/` URI only when the phone number can be safely normalised; do not send messages automatically.
- Status and temperature controls.
- Notes.
- Follow-up information.
- Chronological activity timeline containing call logs, summaries, and recordings.

### 5.4 Call history

- List call records stored in the app.
- Display call type, phone number, matched lead, timestamp, and duration when available.
- Support manual call-log creation.
- If Android call-history access is unavailable, show a clear unavailable state and keep manual logging usable.
- Do not imply that all system calls are being monitored.

### 5.5 Follow-ups

- Today, overdue, upcoming, completed.
- Create, edit, reschedule, complete, and cancel a follow-up.
- Schedule local notifications where notification permission is granted.

### 5.6 Recordings

Recording import may be launched from Android's share sheet or from an in-app file picker.

- Receive one or more shared audio files.
- Copy each file into app-private storage; never rely on a temporary `content://` URI after import.
- Validate file existence, MIME type/extension, and reasonable file size.
- Calculate SHA-256 to detect duplicate imports.
- Suggest a matching lead only when there is reliable metadata; otherwise ask the user to select one.
- Optionally link the recording to an existing call log.
- Play, rename/display, and delete the local copy.
- Show import errors clearly; never silently discard a file.

## 6. Lead classification

Keep lead status and lead temperature as separate fields.

### Status

- `new`
- `contacted`
- `qualified`
- `proposal_sent`
- `won`
- `lost`

### Temperature

- `unrated`
- `hot`
- `warm`
- `cold`

A lead can be Hot while its status is `proposal_sent`.

## 7. Call outcomes

Use a small, editable list of dispositions:

- `connected`
- `interested`
- `follow_up`
- `not_interested`
- `no_answer`
- `busy`
- `wrong_number`
- `other`

Do not infer a call disposition from call duration or call type. Android call metadata does not reveal what the caller and recipient discussed.

## 8. Functional requirements

1. Import `.xlsx` and `.csv` files.
2. Require at least name and phone columns; allow optional company, email, website, and source columns.
3. Preview, validate, and deduplicate before writing to SQLite.
4. Create, read, update, and delete leads, with safe confirmation for destructive actions.
5. Launch the native phone dialer for a lead.
6. Manually create call logs and summaries.
7. Attempt Android call-log sync only after an explicit device proof-of-concept confirms the permission can be granted.
8. Receive Google Phone audio shares through Android share intents.
9. Store recordings in private app storage and metadata in SQLite.
10. Play and delete recordings.
11. Create and manage follow-ups and local notifications.
12. Provide a simple dashboard.
13. Provide a local backup/export path before calling the MVP production-ready.

## 9. Non-functional requirements

- Local-first: the core app works without an internet connection.
- No account, backend, or subscription.
- All SQLite access is through repositories/data sources, never directly from widgets.
- Use transactions for bulk imports and multi-step file/database operations where possible.
- Use database migrations from the first schema version.
- Do not load large audio files fully into memory. Copy using streams.
- Keep recordings private to the app sandbox.
- Preserve a recording file if its database insert fails; clean up orphan files through a recovery routine rather than deleting user data eagerly.
- Use clear loading, empty, permission-denied, and error states.
- Include unit tests for phone normalisation, CSV/XLSX mapping, duplicate detection, database repositories, and recording import metadata.

## 10. Explicit non-goals

Do not build these in the MVP:

- login or authentication;
- backend, REST API, or cloud database;
- multi-user/team management;
- AI summaries, transcription, or lead scoring;
- custom in-app call recording;
- automatic recording of cellular calls by this app;
- WhatsApp automation or message sending;
- email automation;
- complex sales pipeline/kanban;
- integrations with paid CRM platforms;
- cloud sync;
- web or iOS application.

## 11. Acceptance criteria

The MVP is acceptable when:

- the app launches on the realme 11 Pro+ 5G;
- a valid XLSX and CSV file can each be previewed and imported;
- duplicate rows are detected without silently merging unrelated leads;
- leads can be created, edited, searched, filtered, and opened;
- tapping Call opens the native dialer;
- a user can manually log a call and summary;
- a Google Phone recording can be shared to Lead Tracker and copied into private storage;
- the user confirms the associated lead before attachment;
- the recording remains playable after the original shared URI is no longer available;
- duplicate recording imports are detected by checksum;
- follow-ups can be scheduled and completed;
- the app works without network access for core features; and
- data survives app restarts.

Android system call-log reading is not an acceptance blocker unless the Phase 0 permission proof-of-concept succeeds. The app must work without it.
