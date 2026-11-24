# Android Integrations — Lead Tracker

This document separates two capabilities that must not be confused:

1. **Call recording:** handled by Google Phone, outside Lead Tracker.
2. **Call metadata:** optional read access to Android's system call log, subject to hard permission restrictions.

## 1. Device context

- Reference device: realme 11 Pro+ 5G.
- Default Phone app: Google Phone (confirmed by user).
- Google Phone's Call recording settings are visible on the device (confirmed by user).
- The user intends to enable automatic recording in Google Phone.
- Exact Android / realme UI version remains to be verified on-device.

## 2. Configure Google Phone recording manually

Lead Tracker cannot change Google Phone's recording settings. The user configures them in Google Phone:

1. Open Phone.
2. Tap More options → Settings → Call recording.
3. Under Always record, enable Numbers not in your contacts if that is the desired behaviour and the option is available.
4. Optionally configure Selected numbers for contacts saved in the phone's address book.
5. Review the retention setting offered by Google Phone.

Leads imported only into Lead Tracker are not automatically phone contacts. Therefore, enabling recording for unknown numbers can cover numbers not saved in the Android contacts list, if the setting is available and supported. If the user saves selected clients as phone contacts, the selected-number option can be used.

Google Phone availability and options vary by device, carrier, and region. Google states that call participants are notified when recording starts/stops and warns users to comply with applicable law. Do not suppress those notices.

Official guide: https://support.google.com/phoneapp/answer/9803950

## 3. Receiving recordings from Google Phone

Google Phone allows a saved recording to be shared from the call's history when the feature is supported. This is a user-initiated operation; Lead Tracker does not receive a callback automatically when a call ends.

### Expected user flow

1. Open Google Phone.
2. Open the recorded caller/call history.
3. Select the recorded call and use Share.
4. Select Lead Tracker in Android's share sheet.
5. Lead Tracker receives the audio and opens an import-confirmation screen.
6. User chooses the lead and optionally an existing call log.
7. Lead Tracker copies the recording to its app-private storage and persists metadata.

Google Phone help: https://support.google.com/phoneapp/answer/9803950

### Android intent contract

Support at minimum:

- `android.intent.action.SEND` with MIME `audio/*`;
- `android.intent.action.SEND_MULTIPLE` with MIME `audio/*`;
- `Intent.EXTRA_STREAM` for one URI;
- multiple URIs via the supported extra/ClipData representation used by the sending app.

Use a separate intent filter for each action where appropriate and include `android.intent.category.DEFAULT`. Reference: https://developer.android.com/training/basics/intents/filters

Do not assume the Google Phone app always sends the same extension, MIME type, display name, or extra metadata. Add a manual file-picker fallback. Validate the actual payload on the realme device before declaring the integration complete.

### Native bridge responsibilities

Implement a small Kotlin bridge in the existing Flutter `MainActivity` or a dedicated Android activity/service only if the generated Flutter architecture requires it. Do not create a second launcher activity unnecessarily.

- Handle initial activity launch (`onCreate`) and subsequent shares (`onNewIntent`).
- Read `content://` streams via `ContentResolver` while the temporary URI grant is valid.
- Copy streams to an app-private cache import directory.
- Avoid loading the full audio into memory.
- Pass only internal cache path and safe metadata to Dart.
- Queue pending shared items until Flutter is listening so a cold-start share is not lost.
- Clean up cache files only after Flutter confirms successful permanent import, or through a safe stale-temp cleanup policy.
- Handle cancellation, unreadable URIs, missing streams, and multiple shared files.

Do not store the external `content://` URI as the permanent recording path. Do not request `MANAGE_EXTERNAL_STORAGE`, broad storage access, or microphone permission for this feature.

### Flutter recording import

- Accept the copied temporary file.
- Check that the file exists and is non-empty.
- Check extension/MIME where possible; support common audio formats such as M4A/MP4, AMR, and WAV only when decoder support is confirmed.
- Use `crypto` to calculate SHA-256.
- Display original filename, file size, and any duration that can be read reliably.
- Ask user to choose a lead; do not guess solely from filename.
- Optionally let user attach it to an existing call log.
- Copy/move into `ApplicationDocumentsDirectory/recordings/lead_<id>/` with a generated safe filename.
- Insert `call_recordings` metadata into SQLite.
- If the checksum already exists, display the existing recording instead of duplicating it.
- Use `just_audio` to play from the local file path.

## 4. Optional Android call-history access

The `call_log` Flutter package can query Android call history, but Android platform permission policy is a blocker that must be tested before this feature is promised.

### Platform restriction

Android documents `READ_CALL_LOG` as a dangerous, hard-restricted permission. A hard-restricted permission cannot be held unless the installer on record allowlists it. Android users cannot simply override this restriction in the regular app-permission screen.

Android reference: https://developer.android.com/reference/android/Manifest.permission#READ_CALL_LOG

Google Play policy separately requires apps requesting the Call Log permission group to be actively registered as the default Phone or Assistant handler, subject to policy requirements.

Google Play policy: https://support.google.com/googleplay/android-developer/answer/16909972

### Required POC before app integration

On the actual realme device and intended installation method:

1. Build a minimal test app/package with no unrelated features.
2. Investigate the installer/allowlisting status for `READ_CALL_LOG`.
3. Verify whether the permission can legally and technically be granted to this app without making it the default Phone handler.
4. If granted, read a small, recent set of call records with `call_log` and verify number, timestamp, type, duration, and stable record ID.
5. Re-test after reinstall/update if relevant.
6. Record exact OS build, realme UI version, install source, and result.

Do not treat a manifest declaration or a runtime prompt as proof that access works.

### Fallback behaviour

If access is unavailable:

- do not keep requesting the permission;
- do not ask the user to make Lead Tracker the default Phone app;
- disable automatic call-log sync and explain why;
- allow manual call logging;
- allow users to attach recordings shared from Google Phone;
- keep the rest of the app fully functional.

### If the POC passes

Only then add the `call_log` adapter behind `CallHistoryDataSource`.

- Query recent calls on app foreground and on user-triggered Sync Now.
- Do not run a permanent background polling service.
- Store system call IDs and deduplicate with a partial unique index.
- Match by normalised number, but allow multiple possible matches and require confirmation when ambiguous.
- Keep unmatched calls unlinked until the user links them.
- Do not infer call content, interest, or disposition from metadata.
- Do not request `WRITE_CALL_LOG` or delete/modify the phone's call history.

## 5. Phone dialer

Use `url_launcher` with `tel:` to open the default dialer. Do not use direct-call `CALL_PHONE` permission. The user confirms and places the call in the phone app.

## 6. Notification permissions

Request Android notification permission only when the user enables follow-up reminders. Use inexact scheduling by default; do not request exact-alarm access for the MVP. Explain that battery optimisation and OS scheduling can delay notifications.
