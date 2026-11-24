# Technology Stack — Lead Tracker

**Target:** Android-only Flutter app, local-first, no backend, Shorebird OTA patches.

## 1. SDK baseline

- **Flutter 3.38.3 (stable), pinned with FVM** — same pin as the hedged-core-app
  reference project. Commit `.fvmrc`:

  ```json
  { "flutter": "3.38.3", "flavors": {} }
  ```

- Run every command through FVM: `fvm flutter …`, `fvm dart …`.
- Shorebird builds with its own Flutter fork. Always pass
  `--flutter-version=3.38.3` to `shorebird release` so the release matches the
  FVM pin (see [BUILD_AND_RELEASE.md](BUILD_AND_RELEASE.md)).
- Android: set `minSdk` to the highest minimum required by the resolved plugins.
  Keep AGP, Gradle wrapper, Kotlin, compile SDK, and target SDK aligned with the
  Flutter 3.38.3 template and plugin requirements.

## 2. Core stack

| Concern | Technology | Purpose |
|---|---|---|
| App framework | Flutter + Dart | Android UI and app logic |
| UI | Material 3 + theme extensions | `context.colors` / `context.text` |
| State + DI | `flutter_riverpod` + `riverpod_annotation` | Providers, notifiers, DI |
| Provider codegen | `riverpod_generator` + `build_runner` (dev) | Generates `*.g.dart` |
| Routing | `auto_route` + `auto_route_generator` (dev) | Typed routes, tab shell, `*.gr.dart` |
| Local database | `sqflite` | Leads, calls, follow-ups, recording metadata |
| File paths | `path`, `path_provider` | Private database and recording directories |
| XLSX import | `excel` | Read Excel workbooks |
| CSV import | `csv` | Read CSV files |
| File selection | `file_picker` | XLSX/CSV/audio picker |
| Phone launch | `url_launcher` | `tel:` dialer and `wa.me` link |
| Audio playback | `just_audio` | Play imported recordings |
| File integrity | `crypto` | SHA-256 checksum |
| Reminders | `flutter_local_notifications` + `timezone` | Follow-up notifications |
| OTA patches | `shorebird_code_push` | Check/download Shorebird patches |
| Restart after patch | `restart_app` | Relaunch the process so the patch loads |
| App version | `package_info_plus` | Show version/build in Settings |
| Optional call history | `call_log` | Only if the permission POC succeeds |
| Share receiver | Small Kotlin bridge in `MainActivity` | Receive shared recordings |

## 3. Dependency baseline

Versions marked **(hedged)** are the exact versions hedged-core-app resolves on
Flutter 3.38.3, so they are known to work together. For the rest, run
`fvm flutter pub add <pkg>` and accept the latest version that resolves on
3.38.3; record it in `pubspec.lock`.

```yaml
environment:
  sdk: ^3.10.1   # Dart shipped with Flutter 3.38.3

dependencies:
  flutter:
    sdk: flutter

  flutter_riverpod: 3.0.3          # (hedged)
  riverpod_annotation: 3.0.3       # (hedged)
  auto_route: 10.2.3               # (hedged)

  sqflite: ^2.4.2+1                # resolved on 3.38.3 (Milestone 1)
  path: ^1.9.1                     # (Milestone 1)
  path_provider: 2.1.5             # (hedged) — added in Milestone 4

  excel: any
  csv: any
  file_picker: any

  url_launcher: 6.3.2              # (hedged)
  just_audio: any
  crypto: any

  flutter_local_notifications: 19.5.0   # (hedged)
  timezone: any

  shorebird_code_push: 1.1.5       # (hedged)
  restart_app: 1.8.3               # (hedged, needs RestartMode.process)
  package_info_plus: 9.0.0         # (hedged)

  # Add only after the Milestone 0 call-log POC passes:
  # call_log: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: 6.0.0             # (hedged)
  build_runner: 2.7.1              # (hedged)
  riverpod_generator: 3.0.3        # (hedged)
  auto_route_generator: 10.2.6     # (hedged)
  sqflite_common_ffi: ^2.4.0+3     # runs real SQLite in unit tests (Milestone 1)
```

Notes:

- Replace each `any` with a real caret constraint (`^x.y.z`) once it resolves.
  Don't leave `any` in the committed `pubspec.yaml`.
- `file_picker`, `flutter_local_notifications`, and `shorebird_code_push` change
  APIs between majors. Read the installed version's README/changelog before
  writing code.
- `flutter_local_notifications` needs the device's local time zone name to
  schedule with `timezone`. Check its current docs for the recommended way
  (commonly the `flutter_timezone` package) when building Milestone 6.
- `restart_app` must support `RestartMode.process` (1.8.x does). The default mode
  only recreates the activity and Shorebird would not load the patch.
- `flutter_gen_runner` (hedged uses it for typed asset refs) is **optional**. Add it
  only when the app has real image/SVG assets.
- Do not add `receive_sharing_intent` or `share_handler`. Use the Kotlin bridge
  in [ANDROID_INTEGRATIONS.md](ANDROID_INTEGRATIONS.md).
- Commit `pubspec.lock`.

## 4. Lints

Copy hedged-core-app's `analysis_options.yaml` rule list (strict
`flutter_lints` plus ~140 extra rules, `avoid_print`, `prefer_single_quotes`,
`require_trailing_commas`, `directives_ordering`, etc.) with two changes:

- **Remove** the `plugins: - custom_lint` entry (hedged doesn't install it either).
- Exclude generated files: `lib/**.g.dart`, `lib/**.gr.dart`.

## 5. Licensing

Prefer permissive licenses (MIT, BSD, Apache-2.0). Verify each dependency and its
transitive licenses before relying on it. Shorebird's free tier covers a personal
app; check current limits on shorebird.dev.

## 6. Deliberately excluded

- Firebase (any part), Supabase, Appwrite — no backend, no Crashlytics.
- Dio / `http` — no app network calls. (Shorebird's updater does its own networking.)
- `socket_io_client`, the hedged `api` package, interceptors — nothing to talk to.
- PostHog, analytics, chat SDKs, payments, `in_app_update` (no Play Store).
- Flavors / `env/` config — one build only.
- AI SDKs, contacts packages, audio recording packages.
- Background task frameworks — no continuous call polling.
- `permission_handler` — not added by default.
- `freezed` / `json_serializable` — models are small and hand-written with
  `fromMap`/`toMap` for SQLite.

## 7. Useful commands

```bash
fvm install 3.38.3
fvm use 3.38.3
fvm flutter --version
fvm flutter doctor -v

fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run build_runner watch --delete-conflicting-outputs   # while developing

fvm dart format .
fvm flutter analyze
fvm flutter test
fvm flutter run          # debug on device

shorebird release android --artifact apk --flutter-version=3.38.3
shorebird patch android --release-version=<x.y.z+build>
```
