# Database Schema — Lead Tracker

SQLite database file: `lead_tracker.db`

Initial schema version: `1`

Use `sqflite`. Enable foreign keys on every database connection. Store timestamps as UTC Unix milliseconds (`INTEGER`). Store audio files in app-private filesystem storage, never as SQLite BLOBs.

## 1. `leads`

```sql
CREATE TABLE leads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  phone_normalized TEXT,
  company TEXT,
  email TEXT,
  website TEXT,
  source TEXT,
  status TEXT NOT NULL DEFAULT 'new'
    CHECK (status IN ('new','contacted','qualified','proposal_sent','won','lost')),
  temperature TEXT NOT NULL DEFAULT 'unrated'
    CHECK (temperature IN ('unrated','hot','warm','cold')),
  notes TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE INDEX idx_leads_name ON leads(name);
CREATE INDEX idx_leads_phone_normalized ON leads(phone_normalized);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_temperature ON leads(temperature);
```

`phone_normalized` may be NULL for invalid/unknown input. Do not put a global unique constraint on phone; more than one lead may legitimately share a phone number. Import deduplication is a user-visible decision, not a hidden database side effect.

`deleted_at` supports soft deletion. Do not hard-delete a lead that still has recordings without explicit user confirmation and an implemented retention path.

## 2. `call_logs`

```sql
CREATE TABLE call_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id INTEGER,
  source TEXT NOT NULL DEFAULT 'manual'
    CHECK (source IN ('manual','android_call_log')),
  source_record_id TEXT,
  phone TEXT,
  phone_normalized TEXT,
  display_name TEXT,
  call_type TEXT NOT NULL DEFAULT 'unknown'
    CHECK (call_type IN ('incoming','outgoing','missed','rejected','blocked','unknown')),
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  disposition TEXT
    CHECK (disposition IS NULL OR disposition IN (
      'connected','interested','follow_up','not_interested',
      'no_answer','busy','wrong_number','other'
    )),
  summary TEXT,
  called_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE SET NULL
);

CREATE INDEX idx_call_logs_lead_id ON call_logs(lead_id);
CREATE INDEX idx_call_logs_called_at ON call_logs(called_at DESC);
CREATE INDEX idx_call_logs_phone_normalized ON call_logs(phone_normalized);
CREATE UNIQUE INDEX idx_call_logs_external_id
  ON call_logs(source, source_record_id)
  WHERE source_record_id IS NOT NULL;
```

The partial unique index prevents repeated import of a system call entry but permits multiple manual records where `source_record_id` is NULL. `lead_id` may be NULL for an unmatched system call; the user can link it later.

Do not infer `disposition` from Android call type or duration. A connected call does not imply interest.

## 3. `follow_ups`

```sql
CREATE TABLE follow_ups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  note TEXT,
  due_at INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','completed','cancelled')),
  notification_id INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  completed_at INTEGER,
  FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE
);

CREATE INDEX idx_follow_ups_due
  ON follow_ups(status, due_at);
CREATE INDEX idx_follow_ups_lead_id
  ON follow_ups(lead_id);
```

## 4. `call_recordings`

```sql
CREATE TABLE call_recordings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id INTEGER NOT NULL,
  call_log_id INTEGER,
  original_filename TEXT,
  stored_filename TEXT NOT NULL,
  relative_path TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  duration_ms INTEGER,
  file_size_bytes INTEGER NOT NULL,
  sha256 TEXT NOT NULL UNIQUE,
  import_source TEXT NOT NULL
    CHECK (import_source IN ('google_phone_share','file_picker')),
  imported_at INTEGER NOT NULL,
  notes TEXT,
  FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE RESTRICT,
  FOREIGN KEY (call_log_id) REFERENCES call_logs(id) ON DELETE SET NULL
);

CREATE INDEX idx_call_recordings_lead_id
  ON call_recordings(lead_id);
CREATE INDEX idx_call_recordings_call_log_id
  ON call_recordings(call_log_id);
```

Store `relative_path`, not an absolute path that may change across application versions. Resolve it against the app documents directory. Generate stored filenames; do not use untrusted source filenames as paths. Use SHA-256 to avoid duplicate imports.

A recording belongs to a lead. `ON DELETE RESTRICT` intentionally prevents accidental deletion of a lead that has recordings. Implement an explicit delete/reassign flow if needed later.

## 5. `app_settings`

```sql
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at INTEGER NOT NULL
);
```

Suggested keys:

- `default_region` = `IN`
- `default_country_calling_code` = `+91`
- `last_call_history_sync_at` = UTC epoch milliseconds
- `call_history_sync_enabled` = `false` until the permission POC succeeds
- `notification_enabled` = `true` or `false`

Do not store secret credentials; the app has no backend or API keys.

## 6. Database rules

- Start at schema version 1 and use `onUpgrade` migrations for all future changes.
- Enable `PRAGMA foreign_keys = ON`.
- Use transactions and batches for bulk imports.
- Use parameterised SQL.
- Use repositories for CRUD/query access.
- Avoid storing derived counters; calculate dashboard totals with SQL queries.
- Use UTC milliseconds for persisted dates and convert to local time in presentation.
- Write migration tests and repository tests.

## 7. Audio file location

```text
<ApplicationDocumentsDirectory>/recordings/
  lead_101/
    <generated-recording-id>.m4a
  lead_102/
    <generated-recording-id>.amr
```

The extension must come from a validated MIME/filename mapping. Do not blindly preserve path components from an incoming filename.
