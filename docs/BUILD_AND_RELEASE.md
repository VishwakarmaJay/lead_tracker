# Build, release & Shorebird patches

How Lead Tracker is built, signed, released as an APK, and patched over the air.
Adapted from hedged-core-app's `docs/BUILD_AND_RELEASE.md`, minus flavors,
Firebase, and the Play Store.

---

## 1. Toolchain

- Flutter **3.38.3** pinned with FVM (`.fvmrc`). Use `fvm flutter …` / `fvm dart …`.
- Shorebird CLI installed at `~/.shorebird` and logged in to the **personal**
  Shorebird account (`shorebird login`). Never use a work account for this app.
- Shorebird builds with its own Flutter fork. Always pass
  `--flutter-version=3.38.3` on `shorebird release` so the release matches FVM.
  A patch is always built with the same Flutter version as its release.

## 2. Code generation

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Regenerates Riverpod `*.g.dart` and auto_route `app_router.gr.dart`. Generated
files are git-ignored (same as hedged), so run this after every clone or pull and
**before every `shorebird release` or `shorebird patch`**. Never hand-edit them.

## 3. One build, no flavors

There is a single build and a single Shorebird app. No `--flavor`, no `env/`,
no Firebase options. The `applicationId` is fixed before the first release and
never changes afterwards (a new id is a separate app; the old install's data
would be stranded).

## 4. Release signing

Shorebird release APKs are installed by sideloading, and Android only lets an
APK update an existing install if it is signed with the **same key**. Losing
the key means uninstalling, which deletes all local leads and recordings.

1. Create a keystore once (outside the repo), e.g. `~/keys/lead_tracker.jks`.
2. Create `android/key.properties` (git-ignored) with `storePassword`,
   `keyPassword`, `keyAlias`, `storeFile`.
3. Load it in `android/app/build.gradle.kts` and use it for the `release` build type.
4. Make sure `.gitignore` covers `android/key.properties`, `*.jks`, `*.keystore`.
5. Back up the keystore and passwords somewhere safe (password manager).

## 5. First-time Shorebird setup

```bash
shorebird login                 # personal account
shorebird init                  # in the project root; creates shorebird.yaml with this app's app_id
```

- Commit `shorebird.yaml`. The `app_id` is not a secret.
- `shorebird init` adds `shorebird.yaml` to the Flutter assets in `pubspec.yaml`; keep that.
- Leave `auto_update` at its default (on). Shorebird then checks for and downloads
  patches in the background on launch; the `PatchBanner` also lets the user
  download and restart on demand (see §8).
- Add `INTERNET` to the main manifest (Shorebird only — see
  `ANDROID_INTEGRATIONS.md` §7).

## 6. Versioning

- `pubspec.yaml` → `version: x.y.z+build`. `versionName = x.y.z`, `versionCode = build`.
- Every **release** bumps the version (at least `+build`). Android refuses to
  install a lower `versionCode` over a higher one.
- **Patches don't change the version.** A patch targets an existing release
  version and gets its own patch number (1, 2, 3…).

## 7. Release vs patch — which one?

| Change | Ship as |
| --- | --- |
| Dart code: UI, providers, repositories, bug fixes | **Patch** |
| New pure-Dart package (e.g. `csv`, `excel`, `crypto`) | Patch (Shorebird warns if anything native changes) |
| New or upgraded plugin with Android code (`sqflite`, `file_picker`, `just_audio`, notifications, `call_log`…) | **Release** |
| Kotlin (`MainActivity`, share bridge), `AndroidManifest.xml`, Gradle, permissions | **Release** |
| Database schema change (new version / migration) | **Release** (patches can be rolled back) |
| Flutter version change | **Release** |
| New/changed assets | Patch with care (`--allow-asset-diffs` only if you understand why) |

If `shorebird patch` reports native diffs, **don't** force it with
`--allow-native-diffs`; make a new release instead.

**During development the same rule applies to hot reload.** After adding a
plugin with Android code (or changing Kotlin, the manifest, or Gradle), stop
the app and run `fvm flutter run` again. Hot reload / hot restart only swap
Dart code, so the app would call a plugin whose Android side isn't installed:
`MissingPluginException(No implementation found for method … on channel …)`.

## 8. Commands

### New release (APK)

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze && fvm flutter test
shorebird release android --artifact apk --flutter-version=3.38.3
```

Install the APK that Shorebird prints the path to (under
`build/app/outputs/flutter-apk/`) on the phone. **Only APKs built by
`shorebird release` can receive patches**; a plain `flutter build apk` or
`flutter run` install cannot.

### Patch

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze && fvm flutter test
shorebird patch android --release-version=<x.y.z+build>
```

`--release-version=latest` targets the most recent release. Roll back a bad
patch from the Shorebird console.

### Debug

```bash
fvm flutter run          # Shorebird is inactive in debug; the banner stays hidden
```

## 9. Restart after patch (how the app applies patches)

Mirrors hedged's `src/update` feature:

1. On startup the `Patch` notifier asks Shorebird whether a patch is staged
   (`isNewPatchReadyToInstall`) or available (`isNewPatchAvailableForDownload`).
2. `PatchBanner` (above the home bottom navigation) shows **Update** →
   downloading → **Restart now**.
3. **Restart now** calls `Restart.restartApp(mode: RestartMode.process)`, which
   starts a new process so Shorebird boots the patch. The default restart mode
   only recreates the activity, and the patch would be skipped.
4. If the user ignores the banner, the patch still applies on the next cold start.
5. Restart is disabled while an import, recording copy, or database transaction
   is running.

Lead Tracker drops hedged's backend "silent patch" switch (no backend) and the
iOS branch (Android only).

## 10. Release checklist

- [ ] On the personal git identity and personal Shorebird account.
- [ ] `version:` bumped (releases only).
- [ ] Codegen run; nothing hand-edited.
- [ ] `fvm dart format .`, `fvm flutter analyze`, `fvm flutter test` clean.
- [ ] Release vs patch decided with the table in §7.
- [ ] Schema changes only in a release, with a migration test.
- [ ] Signed with the backed-up release keystore.
- [ ] Device test: install/patch → **Restart now** → change visible → existing data intact.
- [ ] No secrets committed (`key.properties`, keystore).

## 11. Config-file map

| Concern | File(s) |
| --- | --- |
| SDK pin | `.fvmrc` |
| Version | `pubspec.yaml` |
| OTA patches | `shorebird.yaml` |
| Signing | `android/key.properties` (git-ignored), `android/app/build.gradle.kts` |
| Permissions / share intent filters | `android/app/src/main/AndroidManifest.xml` |
| Lints | `analysis_options.yaml` |
