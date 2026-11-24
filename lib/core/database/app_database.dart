import 'dart:io';

import 'package:lead_tracker/core/database/migrations/migrations.dart';
import 'package:lead_tracker/core/database/schema.dart';
import 'package:lead_tracker/core/extension/log.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// The database file was written by a newer app version (for example a
/// Shorebird patch that migrated the schema was rolled back).
class DatabaseTooNewException implements Exception {
  const DatabaseTooNewException({
    required this.fileVersion,
    required this.appVersion,
  });

  final int fileVersion;
  final int appVersion;

  @override
  String toString() =>
      'DatabaseTooNewException(file: v$fileVersion, app: v$appVersion)';
}

/// Opens `lead_tracker.db`: foreign keys on, schema v1 on create, migrations on
/// upgrade, a file backup before any upgrade, and a hard stop on downgrade.
Future<Database> openAppDatabase({
  required DatabaseFactory factory,
  required String path,
  int version = currentSchemaVersion,
  Map<int, Migration>? migrations,
  DateTime Function() now = DateTime.now,
}) async {
  final steps = migrations ?? appMigrations;
  await _backupBeforeUpgrade(factory, path, version, now);

  return factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, newVersion) async {
        await _createV1(db, now);
        await _migrate(db, 1, newVersion, steps);
      },
      onUpgrade: (db, oldVersion, newVersion) =>
          _migrate(db, oldVersion, newVersion, steps),
      onDowngrade: (db, oldVersion, newVersion) =>
          throw DatabaseTooNewException(
            fileVersion: oldVersion,
            appVersion: newVersion,
          ),
    ),
  );
}

Future<void> _createV1(Database db, DateTime Function() now) async {
  final batch = db.batch();
  schemaV1.forEach(batch.execute);
  final timestamp = now().toUtc().millisecondsSinceEpoch;
  defaultSettingsV1.forEach((key, value) {
    batch.insert('app_settings', {
      'key': key,
      'value': value,
      'updated_at': timestamp,
    });
  });
  await batch.commit(noResult: true);
}

Future<void> _migrate(
  DatabaseExecutor db,
  int fromVersion,
  int toVersion,
  Map<int, Migration> steps,
) async {
  for (var version = fromVersion + 1; version <= toVersion; version++) {
    final step = steps[version];
    if (step == null) {
      throw StateError('No migration to schema version $version.');
    }
    'Migrating database to v$version'.logInfo();
    await step(db);
  }
}

/// Copies the database file before it is upgraded, so a failed or bad
/// migration never costs the user's data. Backups live next to the database
/// in `backups/`.
Future<void> _backupBeforeUpgrade(
  DatabaseFactory factory,
  String path,
  int targetVersion,
  DateTime Function() now,
) async {
  if (path == inMemoryDatabasePath || !await factory.databaseExists(path)) {
    return;
  }
  final probe = await factory.openDatabase(
    path,
    options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
  );
  final int fileVersion;
  try {
    fileVersion = await probe.getVersion();
  } finally {
    await probe.close();
  }
  if (fileVersion == 0 || fileVersion >= targetVersion) {
    return;
  }

  final backupDir = Directory(p.join(p.dirname(path), 'backups'));
  await backupDir.create(recursive: true);
  final stamp = now().toUtc().millisecondsSinceEpoch;
  final target = p.join(
    backupDir.path,
    'lead_tracker_v${fileVersion}_$stamp.db',
  );
  await File(path).copy(target);
  for (final suffix in const ['-wal', '-shm', '-journal']) {
    final sidecar = File('$path$suffix');
    if (sidecar.existsSync()) {
      await sidecar.copy('$target$suffix');
    }
  }
  'Database backed up before upgrade to v$targetVersion'.logInfo();
}
