import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/database/app_database.dart';
import 'package:lead_tracker/core/database/migrations/migrations.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A fixed clock: 1 Dec 2026 10:00 UTC, advanced manually.
class TestClock {
  DateTime current = DateTime.utc(2026, 12, 1, 10);

  DateTime call() => current;

  void advance(Duration by) => current = current.add(by);
}

/// A real on-disk SQLite database in a temp folder, deleted after the test.
class TestDatabase {
  TestDatabase._(this.directory);

  final Directory directory;

  String get path => p.join(directory.path, 'lead_tracker.db');

  static Future<TestDatabase> create() async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('lead_tracker_');
    addTearDown(() => directory.delete(recursive: true));
    return TestDatabase._(directory);
  }

  Future<Database> open({
    int version = 1,
    Map<int, Migration>? migrations,
    DateTime Function()? now,
  }) async {
    final db = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: path,
      version: version,
      migrations: migrations ?? const {},
      now: now ?? DateTime.now,
    );
    addTearDown(db.close);
    return db;
  }
}

/// Opens a fresh v1 database.
Future<Database> openTestDatabase({DateTime Function()? now}) async {
  final testDb = await TestDatabase.create();
  return testDb.open(now: now);
}
