# Lead Tracker — Claude Code Project Kit

A personal, Android-first Flutter app for managing freelance prospects, tracking calls, keeping call notes, setting follow-ups, and attaching Google Phone call recordings to client records.

**Architecture:** Flutter + Riverpod + SQLite. Local-first. No backend, login, cloud sync, paid API, analytics SDK, or subscription.

**Prepared:** 24 November 2026

## Start here

1. Read `PROJECT_DESCRIPTION.md` to understand the product and MVP boundaries.
2. Read `CLAUDE.md` before asking Claude Code to write code. It contains the project-specific engineering rules.
3. Read `STACK.md`, `ARCHITECTURE.md`, `DATABASE_SCHEMA.md`, and `ANDROID_INTEGRATIONS.md`.
4. Follow the milestone order in `IMPLEMENTATION_PLAN.md`.
5. Paste the prompt in `CLAUDE_CODE_START_PROMPT.md` into Claude Code from the project root.

## Important Android constraints

- Google Phone call recording is performed by Google Phone, not by this app. The user shares a saved recording to Lead Tracker; Lead Tracker copies it into its private app storage and asks the user to confirm the client.
- Android `READ_CALL_LOG` is hard-restricted. An app cannot hold it unless the installer allowlists it. Google Play also restricts call-log permissions to qualifying default Phone/Assistant handler apps. Therefore call-history reading is an experimental device proof-of-concept, not a guaranteed MVP capability. The app must remain useful without it.
- Do not attempt to record cellular call audio inside Flutter, access Google Phone's private data, root the device, or bypass Android permission restrictions.

## Proposed project creation

```bash
flutter create --platforms=android --org com.example lead_tracker
cd lead_tracker
```

Then copy this kit into the project root, replacing the generated `README.md` if desired. Ask Claude Code to follow `CLAUDE_CODE_START_PROMPT.md`.

## Product scope at a glance

- Import prospects from `.xlsx` and `.csv` files.
- Browse, search, filter, add, and edit leads.
- Open a lead's number in the native dialer.
- Record call notes/outcomes manually; optionally import Android call metadata if the permission POC succeeds.
- Receive Google Phone shared audio files through Android `ACTION_SEND` / `ACTION_SEND_MULTIPLE` intents.
- Attach copied audio to a lead and optionally to a call-log entry.
- Play local recordings, manage follow-ups, and view a simple dashboard.
- Keep all records and media on-device.

## No backend means

The app must not require a server or internet connection for its core workflows. Internet permission should not be added unless a future, explicitly approved feature needs it. Do not add Firebase, Supabase, Appwrite, remote analytics, cloud storage, AI APIs, or a hosted database.
