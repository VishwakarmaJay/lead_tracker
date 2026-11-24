# Lead Tracker

A personal, Android-only Flutter app for managing freelance prospects, tracking calls, keeping call notes, setting follow-ups, and attaching Google Phone call recordings to client records.

**Architecture:** Flutter 3.38.3 (FVM) + Riverpod 3 (codegen) + auto_route + SQLite, structured like the hedged-core-app project. Local-first: no backend, login, cloud sync, paid API, analytics SDK, or subscription. Updates ship as **Shorebird** patches to a sideloaded release APK, with an in-app "Restart now" to apply them.

## Start here

1. [`CLAUDE.md`](CLAUDE.md) — the map and engineering rules. Read it before writing code.
2. [`docs/PROJECT_DESCRIPTION.md`](docs/PROJECT_DESCRIPTION.md) — product and MVP scope.
3. [`docs/STACK.md`](docs/STACK.md), [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/CODE_PRACTICES.md`](docs/CODE_PRACTICES.md), [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md), [`docs/ANDROID_INTEGRATIONS.md`](docs/ANDROID_INTEGRATIONS.md).
4. [`docs/BUILD_AND_RELEASE.md`](docs/BUILD_AND_RELEASE.md) — codegen, signing, Shorebird release and patch flow.
5. Follow the milestones in [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md).
6. Start Claude Code with [`docs/CLAUDE_CODE_START_PROMPT.md`](docs/CLAUDE_CODE_START_PROMPT.md).

## Getting started

```bash
fvm install 3.38.3 && fvm use 3.38.3
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # generated files are git-ignored
fvm flutter run
```

## Important Android constraints

- Google Phone records calls, not this app. The user shares a saved recording to Lead Tracker; Lead Tracker copies it into private storage and asks the user to confirm the client.
- `READ_CALL_LOG` is hard-restricted. An app can't hold it unless the installer allowlists it, and Google Play limits it to default Phone/Assistant apps. Call-history reading is an experiment, not a guaranteed feature. The app must stay useful without it.
- Don't record cellular audio in Flutter, read Google Phone's private data, root the device, or bypass Android permission rules.

## Product scope at a glance

- Import prospects from `.xlsx` and `.csv` files.
- Browse, search, filter, add, and edit leads.
- Open a lead's number in the native dialer.
- Log call notes/outcomes manually; optionally import Android call metadata if the permission POC succeeds.
- Receive Google Phone audio shares through `ACTION_SEND` / `ACTION_SEND_MULTIPLE`.
- Attach copied audio to a lead and optionally to a call-log entry.
- Play recordings, manage follow-ups, view a simple dashboard.
- Keep all records and media on-device.
- Receive Shorebird patches and apply them with an in-app restart.

## No backend means

Core workflows never need a server or internet connection. The **only** network use is the Shorebird updater checking for and downloading patches; that is why the app holds the `INTERNET` permission. App code makes no network requests and no user data leaves the device. Do not add Firebase, Supabase, Appwrite, remote analytics, cloud storage, AI APIs, or a hosted database.
