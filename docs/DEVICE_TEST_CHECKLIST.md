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

## F. Database (Milestone 1)

- [ ] Settings → Theme → Dark. Force-stop the app and reopen: it is still Dark (saved in SQLite).
- [ ] Reinstall the **same** build over itself (`adb install -r …`): theme is still Dark.
- [ ] Uninstall and reinstall: theme is back to System (fresh database).

## G. Lead management (Milestone 2)

- [ ] Leads tab, empty: "No leads yet" with **Add lead**.
- [ ] Add a lead with name + `98765 43210`. The phone hint shows "Saved for matching as +919876543210". Save opens the lead.
- [ ] Add a lead with phone `12345`: hint warns it can't be recognised; Save asks "Save anyway". The row shows a ⚠ icon.
- [ ] Add a second lead with `+91 98765 43210`: Save warns the number is already saved, naming the first lead.
- [ ] Edit a lead, change something, press Back: "Discard changes?" appears. Save instead: returns to the detail screen with the change.
- [ ] Search by part of a name, a company, an email, and the last digits of a phone. Status and temperature filters narrow the list; **Clear** resets them.
- [ ] On a lead: change status from the dropdown and temperature from the chips; go back — the list row shows the new status/temperature.
- [ ] **Call** opens the phone's dialer with the number filled in (Lead Tracker doesn't place the call). Make or cancel the call, return to Lead Tracker: the **Log call** sheet opens with the time filled in.
- [ ] Log the call with outcome "Interested", a summary, 5 minutes, temperature Hot. It appears in the lead's Activity and on the Calls tab; the lead is now Hot.
- [ ] Tap the call to edit it; use ⋮ → Delete to remove it (with confirmation).
- [ ] **WhatsApp** (only on leads with a recognised number) opens a chat with that number; nothing is sent.
- [ ] Calls tab → **Log call**: pick a lead in the search sheet, log a call.
- [ ] Delete a lead from ⋮: it disappears; **Undo** in the snack bar brings it back. Its calls stay on the Calls tab either way.
- [ ] Airplane mode on: everything above works except opening WhatsApp's chat.
- [ ] Force-stop and reopen: leads and calls are still there.

## H. XLSX / CSV import (Milestone 3)

Copy `docs/samples/leads_sample.csv` to the phone (Downloads). For XLSX, open the same file in Excel or Google Sheets and save/download it as `.xlsx`.

- [ ] Leads → **Import** icon (top right) → **Choose file**. The picker shows the CSV; pick it.
- [ ] Match columns: Name → "Full Name", Phone → "Mobile No.", Company, Email, Source → "Lead Source", Notes → "Remarks" are pre-selected, with sample values under each.
- [ ] Set Company to "— Not in this file —", then back. Choosing a column used by another field clears that field.
- [ ] **Check rows**: 8 ready, 1 "Number can't be recognised", 1 "Repeated in this file", 2 "Missing name or phone", 1 blank row. Rows show row numbers and reasons.
- [ ] Back (system back or **Back**) returns to the column screen with your choices kept.
- [ ] Leave the import before **Import** — no leads are added.
- [ ] Import again and press **Import 8 leads** → "Imported 8 leads" and "4 rows were skipped" (the blank row is counted separately). **View leads** shows them; the source is "LinkedIn" etc., or "Import: leads_sample.csv" where blank.
- [ ] Import the same file again: the 8 now show under "Number already saved" and are skipped by default. Turn the switch on → "Import 8 leads" creates 8 **new** leads; the first 8 are unchanged.
- [ ] Turn on "Import these too" for the unrecognised number → that lead shows the ⚠ icon in the list.
- [ ] The `.xlsx` version imports the same way (phones stored as numbers in Excel come through without `.0`).
- [ ] Pick a `.xls` or a photo (if the picker allows): a clear "Choose an Excel (.xlsx) or CSV (.csv) file" message.
- [ ] Airplane mode on: import still works.

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
