# Technical References

Reference check date: 24 November 2026. Re-check package versions and platform policies before implementation because they can change.

## Architecture reference

- hedged-core-app (local, read-only reference): `../hedged/hedged-core-app` — see its `CLAUDE.md`, `docs/CODE_STRUCTURE.md`, `docs/CODE_PRACTICES.md`, `docs/BUILD_AND_RELEASE.md`, and `lib/src/update/`. Copy structure and patterns only, never its keys, ids, or config.

## Flutter and tooling

- Flutter release notes: https://docs.flutter.dev/release/release-notes
- Flutter SDK archive: https://docs.flutter.dev/install/archive
- FVM: https://fvm.app/documentation/getting-started
- build_runner: https://pub.dev/packages/build_runner

## Architecture packages

- flutter_riverpod: https://pub.dev/packages/flutter_riverpod
- riverpod_generator: https://pub.dev/packages/riverpod_generator
- Riverpod docs: https://riverpod.dev
- auto_route: https://pub.dev/packages/auto_route

## Feature packages

- sqflite: https://pub.dev/packages/sqflite
- path_provider: https://pub.dev/packages/path_provider
- excel (XLSX): https://pub.dev/packages/excel
- csv: https://pub.dev/packages/csv
- file_picker: https://pub.dev/packages/file_picker
- url_launcher: https://pub.dev/packages/url_launcher
- just_audio: https://pub.dev/packages/just_audio
- crypto: https://pub.dev/packages/crypto
- flutter_local_notifications: https://pub.dev/packages/flutter_local_notifications
- timezone: https://pub.dev/packages/timezone
- package_info_plus: https://pub.dev/packages/package_info_plus
- call_log (Android only, optional): https://pub.dev/packages/call_log

## Shorebird and restart

- Shorebird docs (release, patch, rollback, CLI): https://docs.shorebird.dev
- shorebird_code_push: https://pub.dev/packages/shorebird_code_push
- restart_app: https://pub.dev/packages/restart_app

## Android platform

- Intent filters / receiving ACTION_SEND: https://developer.android.com/training/basics/intents/filters
- READ_CALL_LOG: https://developer.android.com/reference/android/Manifest.permission#READ_CALL_LOG
- Runtime permissions and hard restrictions: https://source.android.com/docs/core/permissions/runtime_perms
- Google Play SMS and Call Log policy: https://support.google.com/googleplay/android-developer/answer/16909972
- App signing: https://docs.flutter.dev/deployment/android#sign-the-app

## Google Phone

- Record, find, and share calls: https://support.google.com/phoneapp/answer/9803950
