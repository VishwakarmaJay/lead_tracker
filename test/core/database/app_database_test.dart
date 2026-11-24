import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/database/app_database.dart';
import 'package:lead_tracker/core/database/schema.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/future.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_database.dart';

Future<Set<String>> _names(Database db, String type) async {
  final rows = await db.query(
    'sqlite_master',
    columns: ['name'],
    where: "type = ? AND name NOT LIKE 'sqlite_%'",
    whereArgs: [type],
  );
  return rows.map((row) => row['name']! as String).toSet();
}

Future<void> _insertLead(Database db, {String status = 'new'}) {
  return db.insert('leads', {
    'name': 'Asha',
    'phone': '9876543210',
    'status': status,
    'created_at': 0,
    'updated_at': 0,
  });
}

Future<int> _leadCount(Database db) async =>
    (await db.rawQuery('SELECT COUNT(*) AS n FROM leads')).single['n']! as int;

void main() {
  test('creates schema v1 with every table and index', () async {
    final db = await openTestDatabase();

    expect(await db.getVersion(), currentSchemaVersion);
    expect(await _names(db, 'table'), {
      'leads',
      'call_logs',
      'follow_ups',
      'call_recordings',
      'app_settings',
    });
    expect(await _names(db, 'index'), {
      'idx_leads_name',
      'idx_leads_phone_normalized',
      'idx_leads_status',
      'idx_leads_temperature',
      'idx_call_logs_lead_id',
      'idx_call_logs_called_at',
      'idx_call_logs_phone_normalized',
      'idx_call_logs_external_id',
      'idx_follow_ups_due',
      'idx_follow_ups_lead_id',
      'idx_call_recordings_lead_id',
      'idx_call_recordings_call_log_id',
    });
  });

  test('turns foreign keys on for every connection', () async {
    final db = await openTestDatabase();
    final rows = await db.rawQuery('PRAGMA foreign_keys');
    expect(rows.single.values.single, 1);
  });

  test('seeds default settings', () async {
    final db = await openTestDatabase();
    final rows = await db.query('app_settings');
    expect({
      for (final row in rows) row['key']: row['value'],
    }, defaultSettingsV1);
  });

  test('enforces CHECK constraints', () async {
    final db = await openTestDatabase();
    await expectLater(
      _insertLead(db, status: 'maybe'),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('data survives closing and reopening the file', () async {
    final testDb = await TestDatabase.create();
    final first = await testDb.open();
    await _insertLead(first);
    await first.close();

    final second = await testDb.open();
    expect(await _leadCount(second), 1);
  });

  group('migrations', () {
    test('upgrade runs the step and backs up the old file first', () async {
      final testDb = await TestDatabase.create();
      final v1 = await testDb.open();
      await _insertLead(v1);
      await v1.close();

      final v2 = await testDb.open(
        version: 2,
        migrations: {
          2: (db) => db.execute('ALTER TABLE leads ADD COLUMN city TEXT'),
        },
        now: () => DateTime.utc(2026, 12),
      );

      expect(await v2.getVersion(), 2);
      final columns = await v2.rawQuery('PRAGMA table_info(leads)');
      expect(columns.map((c) => c['name']), contains('city'));
      expect(await _leadCount(v2), 1);

      final backups = Directory(
        p.join(testDb.directory.path, 'backups'),
      ).listSync().map((f) => p.basename(f.path));
      expect(backups, contains(startsWith('lead_tracker_v1_')));
    });

    test('a fresh install runs v1 plus every migration', () async {
      final testDb = await TestDatabase.create();
      final db = await testDb.open(
        version: 2,
        migrations: {
          2: (db) => db.execute('ALTER TABLE leads ADD COLUMN city TEXT'),
        },
      );
      final columns = await db.rawQuery('PRAGMA table_info(leads)');
      expect(columns.map((c) => c['name']), contains('city'));
      expect(
        Directory(p.join(testDb.directory.path, 'backups')).existsSync(),
        isFalse,
      );
    });

    test('a missing migration step fails instead of skipping it', () async {
      final testDb = await TestDatabase.create();
      await (await testDb.open()).close();

      await expectLater(
        testDb.open(version: 2, migrations: const {}),
        throwsA(isA<StateError>()),
      );
    });

    test('opening a newer database fails with a clear message', () async {
      final testDb = await TestDatabase.create();
      final v2 = await testDb.open(
        version: 2,
        migrations: {2: (db) => db.execute('SELECT 1')},
      );
      await v2.close();

      await expectLater(
        testDb.open().guard(),
        throwsA(
          isA<AppException>()
              .having((e) => e.type, 'type', ErrorType.database)
              .having((e) => e.data, 'data', isA<DatabaseTooNewException>()),
        ),
      );
    });
  });
}
