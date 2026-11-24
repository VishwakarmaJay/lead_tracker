# core

**Path:** `lib/core/` · **Layer:** infrastructure

`core` never imports a feature. The only `src/` imports allowed are `src/theme` (for `context.dart`) and `src/shared/components` (for `async_value.dart`), the same as hedged.

## Contents

| Folder | What lives here |
| --- | --- |
| `constants/keys.dart` | `scaffoldMessengerKey` so notifiers can show snack bars |
| `error/app_exception.dart` | `AppException` + `ErrorType` (`database`, `file`, `permission`, `parse`, `platform`, `other`) |
| `extension/future.dart` | `Future.guard()` — maps file/platform/format errors to `AppException` (database branch added in Milestone 1) |
| `extension/async_value.dart` | `AsyncValue.unfold()` — loading → `AppLoader`, error → `AppError`, data → builder |
| `extension/context.dart` | `context.colors`, `context.text`, `context.isDark` |
| `extension/log.dart` | `.logInfo()`, `.logSuccess()`, `.logWarning()`, `.logError()` |
| `instances/shorebird_instance.dart` | `shorebirdProvider` (keepAlive) — `ShorebirdCodePush` |
| `instances/app_restarter.dart` | `appRestarterProvider` (keepAlive) — restart with `RestartMode.process` |
| `instances/share_bridge.dart` | `shareBridgeProvider` (keepAlive) + `SharedFilePayload` — Dart side of the Kotlin share bridge |

## Notes

- `AppRestarter` and `ShorebirdCodePush` are providers so tests can override them (`test/update/fakes.dart`).
- Share bridge channels: method `lead_tracker/share` (`takePending`, `deleteCached`), event `lead_tracker/share/events` (signal only). Kotlin: `android/app/src/main/kotlin/com/vishwakarmajay/leadtracker/ShareBridge.kt`.
