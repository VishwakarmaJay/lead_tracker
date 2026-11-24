# Code practices — Lead Tracker

How to write code here so the app stays fast, predictable, and safe with user
data. Adapted from hedged-core-app's `docs/CODE_PRACTICES.md`; the
trading/socket/Dio rules are replaced with SQLite, file, and Shorebird rules.

---

## Golden rules

1. **Watch the smallest thing.** `ref.watch(p.select((s) => s.field))` instead
   of the whole provider.
2. **`ref.read` for actions, `ref.watch` for rendering, `ref.listen` for side
   effects** (snack bars, navigation). Never `watch` inside callbacks,
   `initState`, or loops.
3. **`const` everything you can.**
4. **Build methods are pure and cheap.** No I/O, SQL, file access, or
   controller allocation in `build`.
5. **Lists use `ListView.builder` / slivers**, never a `Column` of rows in a
   `SingleChildScrollView`.
6. **Every failing call goes through `.guard()` → `AppException`.**
7. **Render `AsyncValue` with `.unfold()` / `.when`.** Never `.value!`.
8. **No `print`.** Use `.logInfo()` / `.logError()`; never log phone numbers,
   notes, or paths.
9. **No secrets in the repo** (keystore, `key.properties`).

## Riverpod

- Fetch/derive → function provider `@riverpod Future<T> foo(Ref ref)`.
- Mutable flow (forms, import wizard, filters) → `class Foo extends _$Foo`.
- State classes are immutable with `copyWith`. Never mutate fields in place
  and call `notifyListeners`.
- **`family` keys must be stable** (an `int` id, an enum, a value-equal query
  object). Passing a fresh list/object each build defeats caching.
- **Invalidate deliberately.** After a write, `ref.invalidate` the narrowest list
  provider (e.g. `leadListProvider`) instead of patching cached lists by hand.
- **`keepAlive` is a commitment.** Only the singletons listed in
  `ARCHITECTURE.md` §3. Don't add `keepAlive` to a feature provider to hide a
  reload — fix the watch.
- Clean up timers, stream subscriptions, and audio players in `ref.onDispose`.

## Widgets and rebuilds

- Split big pages into `sections/` and `components/`. Keep each `build` short.
- Prefer `ConsumerWidget`. Use `ConsumerStatefulWidget` only when you own a
  controller (text, scroll, animation) — create it in `initState`, dispose it.
- `setState` is for local, ephemeral UI only (expand/collapse).
- Give list rows a stable `ValueKey(id)` when the list filters or reorders.
- Avoid `shrinkWrap: true` on long lists.

## Database

- SQL only in `data/` repositories. Parameterised queries only (`?` arguments).
- Multi-row writes in `db.transaction` / `batch`.
- Repositories map rows to models in one place (`fromMap`/`toMap`).
- Timestamps: UTC milliseconds in the DB, `DateTime.toLocal()` only in the UI.
- Schema changes: new version + `onUpgrade` step + migration test, shipped in a
  **release**, never a patch.
- Large queries (dashboard, search) use indexes from `DATABASE_SCHEMA.md`;
  don't load whole tables to filter in Dart.

## Files and audio

- Stream-copy files; never read a whole recording into memory.
- Generated filenames only; validate extension from MIME/known list.
- Delete a file only after its DB row is gone (or inside an explicit cleanup
  routine). Never leave a DB row pointing at a missing file without showing it.
- One `AudioPlayer` at a time; dispose it when the player screen closes.
- Spreadsheet parsing of big files runs in an isolate (`compute`).

## Async and errors

- `.guard()` converts `DatabaseException`, `FileSystemException`,
  `PlatformException`, `FormatException` into `AppException` with a safe message.
- Branch on `ErrorType` for UI (e.g. `permission` → explain + settings link;
  `file` → retry/cleanup).
- No fire-and-forget that can throw silently; `unawaited` only with a logged
  `catchError`.
- Long operations (import, recording copy) register in
  `busyOperationsProvider` so **Restart now** is disabled while they run.

## Navigation

- Typed auto_route routes only: `context.router.push(LeadDetailRoute(id: id))`.
- New `@RoutePage` → register in `app_router.dart` → rerun codegen.
- Shares arriving while the app is open push `RecordingImportRoute`; don't
  push it from inside the Kotlin bridge.

## Shorebird

- Assume any Dart change may ship as a patch: keep data formats backwards
  compatible within a release.
- Don't put feature flags or behaviour in native code you may want to patch later.
- Never call `Restart.restartApp` from anywhere except the `Patch` notifier.
- Test the patch → restart flow on the real device for every release.

## Generated code

- Never edit `*.g.dart` / `*.gr.dart`. Change the source and rerun
  `fvm dart run build_runner build --delete-conflicting-outputs`.
- Delete orphaned generated files when their source is removed.

## Anti-patterns checklist

- ❌ `ref.watch(bigProvider)` for one field → ✅ `.select`.
- ❌ `ref.watch` in `onTap` / `initState` → ✅ `ref.read` / `ref.listen`.
- ❌ SQL or `File` calls in a widget → ✅ repository / service.
- ❌ Concatenated SQL → ✅ parameterised queries.
- ❌ Reading a whole audio file into memory → ✅ streams.
- ❌ `Column` of N rows in a scroll view → ✅ `ListView.builder`.
- ❌ Controllers created in `build` → ✅ `initState` + dispose.
- ❌ `.value!` on `AsyncValue` → ✅ `.unfold()` / `.when`.
- ❌ `Theme.of(context)` for colors → ✅ `context.colors` / `context.text`.
- ❌ Schema migration in a patch → ✅ release.
- ❌ `RestartMode.platformDefault` for patches → ✅ `RestartMode.process`.
- ❌ Any network call from app code → ✅ none (Shorebird only).

## Before you finish a milestone

- [ ] Codegen run; nothing hand-edited.
- [ ] Rebuilds scoped; `const` applied; long lists use builders.
- [ ] Controllers, players, subscriptions disposed.
- [ ] Failures go through `.guard()`; UI handles loading/empty/error.
- [ ] No `print`, no PII in logs, no secrets committed.
- [ ] `fvm dart format .`, `fvm flutter analyze`, `fvm flutter test` clean.
- [ ] `MODULE.md` updated for each touched feature.
