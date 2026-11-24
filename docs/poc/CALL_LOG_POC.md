# POC — Can a sideloaded Lead Tracker hold `READ_CALL_LOG`?

**Status:** prepared, **not yet run** (needs the realme 11 Pro+ 5G).
**Decides:** whether Milestone 5 (call-history sync) goes ahead or is marked blocked.

## What we already know

- `READ_CALL_LOG` is a dangerous, **hard-restricted** permission. An app can only
  hold it if the installer on record allowlists it; a runtime prompt alone is
  not enough. (Android reference: `Manifest.permission#READ_CALL_LOG`, and
  "Runtime permissions → hard restrictions" on source.android.com.)
- Google Play limits it to default Phone/Assistant apps. That policy doesn't
  apply to a sideloaded APK, but the platform restriction above still does.
- Lead Tracker will be installed by **sideloading the Shorebird release APK**
  (tapping the APK in a file manager → Android Package Installer). That is the
  install path this POC must test. `adb install` is not how the app is
  distributed, so its result is only a comparison.

## What is not known yet

Whether Android/realme UI on this phone lets a Package-Installer-sideloaded app
be granted `READ_CALL_LOG` without becoming the default Phone app.

## Setup in the code (Milestone 0)

- `READ_CALL_LOG` is declared **only** in `android/app/src/debug/AndroidManifest.xml`.
  It is not in the main/release manifest and is never requested at runtime.
- No call-log code or `call_log` package exists yet. If the permission can be
  held, reading real records is the first task of Milestone 5.

## Procedure

1. Note device details: Settings → About device → Android version, realme UI
   version, build number, security patch.
2. Build the debug APK:
   `fvm flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk`
3. **Method A — Package Installer (the real install path).**
   Uninstall any existing Lead Tracker. Copy the APK to the phone and install it
   by tapping it in Files.
   - App info → Permissions: is **Call logs** listed? Can it be switched to
     Allow? Does Android show "Restricted setting" / a greyed-out switch?
   - If a "restricted setting" dialog appears, check App info → ⋮ for
     **Allow restricted settings**, and record whether that makes it grantable.
   - With USB debugging on, record the permission state:
     `adb shell dumpsys package com.vishwakarmajay.leadtracker | grep -i -A3 READ_CALL_LOG`
     and also:
     `adb shell dumpsys package com.vishwakarmajay.leadtracker | grep -i -e installerPackageName -e restrict`
4. **Method B — adb (comparison only).**
   `adb uninstall com.vishwakarmajay.leadtracker` then `adb install app-debug.apk`,
   and repeat the checks in step 3.
5. Fill in the results table below and pick the decision.

Do **not** make Lead Tracker the default Phone app, root the device, or use any
other workaround.

## Results

| Field | Value |
| --- | --- |
| Date tested | |
| Android version | |
| realme UI version | |
| Build number / security patch | |
| Method A: Call logs permission visible? | |
| Method A: can it be set to Allow? | |
| Method A: "restricted setting" shown? Allowed after ⋮ menu? | |
| Method A: `dumpsys` permission line | |
| Method B (adb): can it be set to Allow? | |
| Notes | |

## Decision

- **Method A can grant it** → Milestone 5 goes ahead: add `call_log`, move the
  permission to the main manifest (release), build the
  `CallHistoryDataSource` adapter behind the availability state.
- **Method A cannot grant it** → mark Milestone 5 **blocked**, remove the
  permission from the debug manifest, keep manual call logging. Do not ask the
  user to change the default Phone app.
