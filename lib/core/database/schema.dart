/// Schema version 1 — mirrors docs/DATABASE_SCHEMA.md exactly.
///
/// Never edit these statements after the first release. Every later change is
/// a new entry in `migrations/migrations.dart`, shipped in a full release.
library;

const databaseFileName = 'lead_tracker.db';

/// Bump together with a new migration. See docs/DATABASE_SCHEMA.md §6a.
const currentSchemaVersion = 1;

const schemaV1 = <String>[
  '''
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
)''',
  'CREATE INDEX idx_leads_name ON leads(name)',
  'CREATE INDEX idx_leads_phone_normalized ON leads(phone_normalized)',
  'CREATE INDEX idx_leads_status ON leads(status)',
  'CREATE INDEX idx_leads_temperature ON leads(temperature)',
  '''
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
)''',
  'CREATE INDEX idx_call_logs_lead_id ON call_logs(lead_id)',
  'CREATE INDEX idx_call_logs_called_at ON call_logs(called_at DESC)',
  'CREATE INDEX idx_call_logs_phone_normalized ON call_logs(phone_normalized)',
  '''
CREATE UNIQUE INDEX idx_call_logs_external_id
  ON call_logs(source, source_record_id)
  WHERE source_record_id IS NOT NULL''',
  '''
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
)''',
  'CREATE INDEX idx_follow_ups_due ON follow_ups(status, due_at)',
  'CREATE INDEX idx_follow_ups_lead_id ON follow_ups(lead_id)',
  '''
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
)''',
  'CREATE INDEX idx_call_recordings_lead_id ON call_recordings(lead_id)',
  'CREATE INDEX idx_call_recordings_call_log_id ON call_recordings(call_log_id)',
  '''
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at INTEGER NOT NULL
)''',
];

/// Rows written to `app_settings` when the database is first created.
const defaultSettingsV1 = <String, String>{
  'default_region': 'IN',
  'default_country_calling_code': '+91',
  'call_history_sync_enabled': 'false',
  'notification_enabled': 'false',
  'theme_mode': 'system',
};
