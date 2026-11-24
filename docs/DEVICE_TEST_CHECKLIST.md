# Device test checklist — realme 11 Pro+ 5G

Run these on the real phone. Mocked tests do not count for Android integrations
or Shorebird. Record pass/fail and notes for each line.

Device details: Android ____ · realme UI ____ · build ____ · Google Phone version ____

## A. Debug build basics

```bash
fvm flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk   # or fvm flutter run
```

- [ ] App launches as **Lead Tracker**; Splash → Dashboard.
- [ ] All five tabs open (Dashboard, Leads, Calls, Follow-ups, Settings).
- [ ] Settings → Theme: System / Light / Dark switch the whole app.
- [ ] Settings → Version shows `1.0.0 (1) · updates off in this build` (debug builds have no Shorebird).
- [ ] No update banner is shown in debug builds.

## B. Google Phone share POC (Milestone 0)

Make a short test call with Google Phone recording on (both parties are notified by Google Phone).

- [ ] **Cold start:** force-stop Lead Tracker. In Google Phone open the recorded call → Share → Lead Tracker. The app opens on **Shared files** with one card.
- [ ] Card shows name, MIME type, size (non-zero), received time, cache path. Write down the MIME type and file extension Google Phone sends: ________
- [ ] **Warm start:** with Lead Tracker open on any tab, share another recording. **Shared files** opens automatically with the new card.
- [ ] **Multiple:** if Google Phone allows sharing several recordings at once, share two. Two cards appear (or note that it only shares one).
- [ ] **Rotation/recents:** after a share, switch to another app and back via Recents. No duplicate card appears.
- [ ] **Discard:** tap Discard → confirm. The card disappears. The recording is still in Google Phone.
- [ ] **Other sender:** share an audio file from Files/WhatsApp. It is received too (note MIME type).
- [ ] Settings → Shared files opens the same screen.

## C. Call-log POC

Follow `docs/poc/CALL_LOG_POC.md` and fill in its results table.

## D. Release signing (once, before the first release)

```bash
mkdir -p ~/keys
keytool -genkeypair -v -keystore ~/keys/lead_tracker.jks -keyalg RSA -keysize 2048 -validity 10000 -alias leadtracker
```

Create `android/key.properties` (git-ignored) with an **absolute** `storeFile` path:

```properties
storePassword=<your store password>
keyPassword=<your key password>
keyAlias=leadtracker
storeFile=/Users/<you>/keys/lead_tracker.jks
```

- [ ] Keystore and both passwords backed up in your password manager.
- [ ] `git status` does not show `key.properties` or the `.jks`.

## E. Shorebird release and patch → Restart now

```bash
shorebird login                     # personal account
shorebird init                      # once; commits shorebird.yaml (adds it to pubspec assets)
fvm dart run build_runner build --delete-conflicting-outputs
shorebird release android --artifact apk --flutter-version=3.38.3
```

- [ ] Uninstall the debug build (different signature), then install the APK Shorebird printed (`build/app/outputs/flutter-apk/app-release.apk`) by tapping it in Files.
- [ ] Settings → Version shows `1.0.0 (1)` with no "updates off" note.
- [ ] Make a small visible Dart-only change (e.g. the Dashboard placeholder text), then:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
shorebird patch android --release-version=1.0.0+1
```

- [ ] Fully close and reopen the app (with phone online). Within a few seconds the banner shows **Update ready** (auto-update already downloaded it) or **A new update is available** → tap **Update**.
- [ ] Tap **Restart now**. The app relaunches by itself (not just back to the same screen).
- [ ] The patched text is visible. Settings → Version shows `· patch 1`.
- [ ] The banner does **not** come back after another close/reopen.
- [ ] Airplane mode on → open the app: no banner, no error, everything works.
