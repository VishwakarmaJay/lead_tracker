# settings

**Path:** `lib/src/settings/` · **Layer:** feature

## Data

- `data/models/app_settings.dart` — `AppSettingKey` (stable table keys) and typed `AppSettings` (falls back to defaults for missing/unreadable values).
- `data/settings_repository.dart` — `SettingsRepository`: `readAll`, `read`, `write` (insert-or-replace).

## Providers

- `settingsProvider` (keepAlive, `Settings` notifier) — loaded during startup. `setThemeMode` saves optimistically and rolls back on failure.
- `appInfoProvider` — version, build, Shorebird patch number.

The theme mode (`src/theme`) reads from and saves through `settingsProvider`.

## UI

`SettingsPage` (`SettingsRoute`, tab): theme mode, **Shared files** link, version. Later milestones add default country code, reminders toggle, call-history status.

## Tests

`test/settings/settings_test.dart` (including theme persisting across sessions).
