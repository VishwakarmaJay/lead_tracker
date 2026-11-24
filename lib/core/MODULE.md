# core

**Path:** `lib/core/` · **Layer:** infrastructure

`core` never imports a feature. The only `src/` imports allowed are `src/theme` (for `context.dart`) and `src/shared/components` (for `async_value.dart`), the same as hedged.

## Contents

| Folder | What lives here |
| --- | --- |
| `database/schema.dart` | Schema v1 SQL (frozen), `currentSchemaVersion`, default settings rows |
| `database/migrations/migrations.dart` | `appMigrations` — one step per version above 1 (empty today) |
| `database/app_database.dart` | `openAppDatabase()` — foreign keys on, create/migrate, backup before upgrade, `DatabaseTooNewException` on downgrade |
| `database/db_value.dart` | `DbValue` enums ↔ stable strings, `DateTime.toDb()` / `dateFromDb()` (UTC ms) |
| `instances/app_database_instance.dart` | `appDatabaseProvider` (keepAlive) — opens `<databases>/lead_tracker.db` |
| `utils/phone_normalizer.dart` | `PhoneNormalizer` → E.164 or null (default `+91`) |
| `constants/keys.dart` | `scaffoldMessengerKey` so notifiers can show snack bars |
| `error/app_exception.dart` | `AppException` + `ErrorType` (`database`, `file`, `permission`, `parse`, `platform`, `other`) |
| `extension/future.dart` | `Future.guard()` — maps database (unique/foreign-key/check messages, newer-database), file, platform, and format errors to `AppException` |
| `extension/async_value.dart` | `AsyncValue.unfold()` — error → `AppError` (AppException message), data → builder (kept on screen while refreshing), else `AppLoader` |
| `extension/context.dart` | `context.colors`, `context.text`, `context.isDark` |
| `extension/log.dart` | `.logInfo()`, `.logSuccess()`, `.logWarning()`, `.logError()` |
| `instances/shorebird_instance.dart` | `shorebirdProvider` (keepAlive) — `ShorebirdCodePush` |
| `instances/app_restarter.dart` | `appRestarterProvider` (keepAlive) — restart with `RestartMode.process` |
| `instances/phone_launcher.dart` | `phoneLauncherProvider` — `openDialer` (`tel:`, never places the call) and `openWhatsApp` (`wa.me`); injectable opener for tests |
| `utils/formatters.dart` | `formatTime`, `formatDate`, `formatDateTime` (Today/Yesterday), `formatCallDuration` |
| `instances/share_bridge.dart` | `shareBridgeProvider` (keepAlive) + `SharedFilePayload` — Dart side of the Kotlin share bridge |

## Notes

- `AppRestarter` and `ShorebirdCodePush` are providers so tests can override them (`test/update/fakes.dart`).
- Share bridge channels: method `lead_tracker/share` (`takePending`, `deleteCached`), event `lead_tracker/share/events` (signal only). Kotlin: `android/app/src/main/kotlin/com/vishwakarmajay/leadtracker/ShareBridge.kt`.
