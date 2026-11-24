import 'package:sqflite/sqflite.dart';

/// Upgrades the schema by one version.
typedef Migration = Future<void> Function(DatabaseExecutor db);

/// Key = the version a migration upgrades **to**. Version 1 is the base
/// schema in `schema.dart`, so the first entry will be `2`.
///
/// Rules (docs/DATABASE_SCHEMA.md §6, §6a):
/// - Never edit a migration that has shipped; add a new one.
/// - Bump `currentSchemaVersion` in `schema.dart` with it.
/// - Ship it in a full Shorebird release, never in a patch.
/// - Add a migration test in `test/core/database/`.
final Map<int, Migration> appMigrations = {};
