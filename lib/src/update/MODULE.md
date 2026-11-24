# update

**Path:** `lib/src/update/` · **Layer:** feature · **Reference:** hedged-core-app `lib/src/update`

Shorebird over-the-air patches with an in-app restart.

## How it works

- `patchProvider` (`Patch` notifier) → `PatchStatus`:
  - `build()`: Shorebird unavailable (debug / non-Shorebird builds) → `hidden`; patch already staged (auto-update downloaded it) → `readyToRestart`; patch available → `available`; check fails (offline) → `hidden`.
  - `download()`: `downloading` → `downloadUpdateIfAvailable()` → confirms with `isNewPatchReadyToInstall()` → `readyToRestart`. On error: snack bar, back to `available`.
  - `restart()`: `appRestarterProvider.restartProcess()` (`RestartMode.process`). If the platform refuses, a snack bar asks the user to reopen the app.
- `PatchBanner` (`ui/components/patch_banner.dart`): "A new update is available → Update" → "Downloading…" → "Update ready → Restart now". **Restart now** is disabled while `busyOperationsProvider > 0`.

## Differences from hedged

- No backend "silent patch" flag.
- No iOS branch (Android only).
- Restarter is injectable for tests.

## Depends on

`core/instances/shorebird_instance.dart`, `core/instances/app_restarter.dart`, `src/shared` (snack bar, busy operations).

## Tests

`test/update/patch_provider_test.dart`, `test/update/patch_banner_test.dart`. The real patch flow must also pass `docs/DEVICE_TEST_CHECKLIST.md` §E.
