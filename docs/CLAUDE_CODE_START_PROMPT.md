# Prompt to start Claude Code

Open Claude Code from the root of the Flutter project and paste:

---

You are working on **Lead Tracker**, a personal Android-only Flutter application. First read these project documents completely:

- `CLAUDE.md`
- `PROJECT_DESCRIPTION.md`
- `STACK.md`
- `ARCHITECTURE.md`
- `DATABASE_SCHEMA.md`
- `ANDROID_INTEGRATIONS.md`
- `IMPLEMENTATION_PLAN.md`

Do not start implementing all features at once.

## Your first task

Implement **Milestone 0 only** from `IMPLEMENTATION_PLAN.md`.

1. Inspect the repository and current Flutter/Android configuration. Preserve any working configuration.
2. If no Flutter project exists, create an Android-only Flutter project using the current stable Flutter SDK.
3. Confirm the Flutter/Dart/Android toolchain and report any missing prerequisites.
4. Add only the dependencies needed for the initial app shell and a minimal Android audio-share POC. Resolve versions compatible with the installed Flutter SDK and inspect current package documentation before using APIs.
5. Create a Material 3 app shell with placeholder navigation for Dashboard, Leads, Calls, Follow-ups, and Settings.
6. Implement a proof-of-concept receiver for Google Phone shared audio using Android `ACTION_SEND` / `ACTION_SEND_MULTIPLE`. Handle cold start and warm start. Copy `content://` data through `ContentResolver` into app-private cache using streaming; do not request broad storage access.
7. Add a simple screen that displays the received file name, MIME type, size, and local cache path, with a safe error state. Do not yet create the full recording database or lead workflow.
8. Investigate `READ_CALL_LOG` restrictions and document the result as a separate POC. Do not assume a runtime permission prompt is enough. Do not implement a bypass. The rest of the app must not depend on this permission.
9. Add a short device test checklist for the realme 11 Pro+ 5G with Google Phone.
10. Run formatting, `flutter analyze`, tests, and an Android debug build. Report actual command results; do not claim success if a command was not run.

## Constraints

- No backend, login, cloud, Firebase, analytics, paid API, AI, or internet dependency.
- Do not implement call recording inside Lead Tracker. Google Phone records; the user shares the recording.
- Do not add `WRITE_CALL_LOG`, `PROCESS_OUTGOING_CALLS`, microphone, contacts, `MANAGE_EXTERNAL_STORAGE`, or unrelated permissions.
- Do not declare call-history sync complete until the physical-device POC succeeds.
- Follow `CLAUDE.md` and stop after Milestone 0. Summarise changes and wait for the next instruction.

---
