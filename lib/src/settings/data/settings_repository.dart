import 'package:lead_tracker/core/database/db_value.dart';
import 'package:lead_tracker/core/extension/future.dart';
import 'package:lead_tracker/core/instances/app_database_instance.dart';
import 'package:lead_tracker/src/settings/data/models/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'settings_repository.g.dart';

/// All SQL for `app_settings` (key/value).
class SettingsRepository {
  SettingsRepository(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Database _db;
  final DateTime Function() _now;

  Future<AppSettings> readAll() {
    return Future(() async {
      final rows = await _db.query('app_settings', columns: ['key', 'value']);
      return AppSettings.fromRaw({
        for (final row in rows) row['key']! as String: row['value'] as String?,
      });
    }).guard();
  }

  Future<String?> read(AppSettingKey key) {
    return Future(() async {
      final rows = await _db.query(
        'app_settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key.key],
        limit: 1,
      );
      return rows.isEmpty ? null : rows.first['value'] as String?;
    }).guard();
  }

  /// Inserts or replaces one value.
  Future<void> write(AppSettingKey key, String? value) {
    return _db.insert('app_settings', {
      'key': key.key,
      'value': value,
      'updated_at': _now().toDb(),
    }, conflictAlgorithm: ConflictAlgorithm.replace).guard();
  }
}

@riverpod
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(appDatabaseProvider).requireValue);
