# Prompt to start Claude Code

Open Claude Code from the project root and paste:

---

You are working on **Lead Tracker**, a personal Android-only Flutter app. First read completely:

- `CLAUDE.md` (project root)
- `docs/PROJECT_DESCRIPTION.md`
- `docs/STACK.md`
- `docs/ARCHITECTURE.md`
- `docs/CODE_PRACTICES.md`
- `docs/DATABASE_SCHEMA.md`
- `docs/ANDROID_INTEGRATIONS.md`
- `docs/BUILD_AND_RELEASE.md`
- `docs/IMPLEMENTATION_PLAN.md`

The architecture follows the hedged-core-app project (feature-first `lib/src/<feature>/{ui,providers,data}`, `lib/core/` infra, Riverpod 3 codegen, auto_route, Shorebird + restart after patch). Do not start implementing all features at once.

## Your first task

Implement **Milestone 0 only** from `docs/IMPLEMENTATION_PLAN.md`.

1. Inspect the repository and the current Flutter/Android configuration. Preserve working configuration.
2. Pin Flutter 3.38.3 with FVM and confirm the toolchain (`fvm flutter doctor -v`). Report missing prerequisites.
3. Ask me for the final Android `applicationId` before the first Shorebird release.
4. Add only the dependencies the skeleton, update feature, and share POC need, using the versions in `docs/STACK.md`. Inspect each package's current API before using it.
5. Build the hedged-style skeleton: `core/` (AppException, `.guard()`, `.unfold()`, context/log extensions), theme extensions, shared components, auto_route router with a `TabsRouter` home shell (Dashboard, Leads, Calls, Follow-ups, Settings placeholders). Run codegen. Add `MODULE.md` files.
6. Build `src/update/` (Shorebird `Patch` notifier + `PatchBanner` + restart with `RestartMode.process`) and add `INTERNET` to the main manifest for Shorebird only.
7. Set up release signing with a git-ignored `key.properties` and keystore. Do not commit secrets.
8. Implement the share-intent POC (Kotlin bridge, cold/warm start, stream copy to cache) and a debug screen showing name, MIME type, size, and cache path.
9. Investigate `READ_CALL_LOG` with the sideload install method and document the result. No bypass; nothing else may depend on it.
10. Write a device checklist for the realme 11 Pro+ 5G covering the share POC and the patch → **Restart now** flow.
11. Run codegen, `fvm dart format .`, `fvm flutter analyze`, `fvm flutter test`, and a debug build. Report the real command results. Give me the exact `shorebird init`, `shorebird release`, and `shorebird patch` commands to run, since they need my Shorebird account.

## Constraints

- No backend, login, cloud, Firebase, analytics, paid API, AI, or network calls from app code. `INTERNET` is only for Shorebird.
- Do not record calls inside Lead Tracker. Google Phone records; the user shares.
- Do not add `WRITE_CALL_LOG`, `PROCESS_OUTGOING_CALLS`, microphone, contacts, `MANAGE_EXTERNAL_STORAGE`, or unrelated permissions.
- Do not copy anything hedged-specific (keys, Shorebird app ids, Firebase config, branding) — only structure and patterns.
- Never hand-edit generated files.
- Stop after Milestone 0. Summarise the changes and wait for the next instruction.

---
