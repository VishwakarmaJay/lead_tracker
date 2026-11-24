# Technology Stack — Lead Tracker

**Target:** Android-only Flutter application, local-first, no backend.

## 1. SDK baseline

- Flutter: stable channel, Flutter 3.50.x line (Dart 3.14.x line as of 24 November 2026).
- Use the latest stable patch available when creating the project. Do not use beta/dev for the MVP.
- Android: use the minimum SDK required by the resolved Flutter plugins and the target device; inspect package requirements before setting `minSdk`.
- Keep the Android Gradle Plugin, Gradle wrapper, Kotlin, compile SDK, and target SDK aligned with the selected Flutter stable template and current plugin requirements. Do not downgrade generated project configuration to match an old tutorial.

Official Flutter release notes: https://docs.flutter.dev/release/release-notes

## 2. Core stack

| Concern | Technology | Purpose |
|---|---|---|
| App framework | Flutter + Dart | Android UI and app logic |
| UI | Material 3 | Simple native-feeling interface |
| State management | `flutter_riverpod` | State and dependency injection |
| Local database | SQLite via `sqflite` | Leads, calls, follow-ups, recording metadata |
| File paths | `path` | Safe path joins |
| App directories | `path_provider` | Private database and recording directories |
| XLSX import | `excel` | Read Excel workbooks |
| CSV import | `csv` | Read comma-separated files |
| File selection | `file_picker` | User-selected XLSX/CSV/audio files |
| Phone launch | `url_launcher` | Open native dialer and WhatsApp link |
| Audio playback | `just_audio` | Play imported recordings |
| File integrity | `crypto` | SHA-256 recording checksum |
| Local reminders | `flutter_local_notifications` + `timezone` | Follow-up reminders |
| Optional call history | `call_log` | Read Android call metadata only if permission POC succeeds |
| Android share receiver | Small Kotlin bridge using Android intents | Receive shared recording files; avoid an additional Flutter package |

## 3. Dependency baseline

The following are current stable package versions observed on pub.dev on 24 November 2026. Recheck compatibility before adding them; pub.dev versions can change.

```yaml
dependencies:
  flutter:
    sdk: flutter

  flutter_riverpod: ^3.5.0

  sqflite: ^2.4.6
  path: ^1.9.1
  path_provider: ^2.1.6

  excel: ^4.0.6
  csv: ^8.0.0
  file_picker: ^13.4.1

  url_launcher: ^6.3.3
  just_audio: ^0.10.6
  crypto: ^3.0.8

  flutter_local_notifications: ^23.0.4
  timezone: ^0.11.2

  # Add only after Android permission proof-of-concept:
  # call_log: ^6.0.1
```

Notes:

- `timezone: ^0.11.2` is the current stable baseline observed on pub.dev on 24 November 2026. Recheck compatibility before resolving.
- `path` should be resolved to the latest stable compatible release with `flutter pub add path` if the exact constraint above is no longer compatible.
- `file_picker` has had major API changes in its 13.x line. Read the installed version's API/changelog; do not copy an old `pickFiles()` example without checking the current API.
- `flutter_local_notifications` is actively versioned. Follow the installed release's initialization and Android scheduling instructions; do not copy code from an older major version.
- Add `call_log` only after proving that the target installation can hold `READ_CALL_LOG`. Its presence in pubspec does not grant that permission.
- Do not add `receive_sharing_intent` or `share_handler` by default. Use the small Kotlin intent receiver described in `ANDROID_INTEGRATIONS.md` so the app can control temporary content-URI copying and error handling.
- Keep `pubspec.lock` committed for reproducible builds.

## 4. Licensing approach

Prefer permissive open-source dependencies (MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0). Verify each dependency's license and transitive dependency licenses before release. The Flutter SDK itself has its own license; this project does not need a paid licence for the listed packages.

## 5. Packages deliberately excluded

- Firebase / Firestore / FCM: no cloud backend or push notifications needed.
- Supabase / Appwrite: no backend.
- Dio / HTTP client: no remote API requirement.
- AI SDKs: no AI feature in MVP.
- Contacts packages: no need to import or read the phone's contacts; leads are imported from Excel/CSV.
- Audio recording packages: the app does not record cellular audio.
- Background task frameworks: no continuous call polling; sync is foreground-only if it becomes technically available.
- `permission_handler`: do not add it automatically. Use the selected integration's documented permission flow and platform APIs; do not assume it can bypass hard-restricted permissions.

## 6. Useful commands

```bash
flutter --version
flutter doctor -v
flutter create --platforms=android --org com.example lead_tracker
cd lead_tracker
flutter pub add flutter_riverpod sqflite path path_provider excel csv file_picker url_launcher just_audio crypto
flutter pub add flutter_local_notifications timezone
flutter pub get
flutter analyze
flutter test
```

Add `call_log` separately only after its proof-of-concept gate is passed.
