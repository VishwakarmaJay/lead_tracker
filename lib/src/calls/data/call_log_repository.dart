import 'package:lead_tracker/core/database/db_value.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/future.dart';
import 'package:lead_tracker/core/instances/app_database_instance.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'call_log_repository.g.dart';

/// All SQL for `call_logs`.
class CallLogRepository {
  CallLogRepository(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Database _db;
  final DateTime Function() _now;

  Future<int> createCallLog(CallLogDraft draft) {
    final now = _now().toDb();
    return _db.insert('call_logs', {
      ...draft.toMap(),
      'created_at': now,
      'updated_at': now,
    }).guard();
  }

  Future<CallLog?> getCallLogById(int id) {
    return Future(() async {
      final rows = await _db.query(
        'call_logs',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : CallLog.fromMap(rows.first);
    }).guard();
  }

  Future<void> updateCallLog(CallLog callLog) {
    return Future(() async {
      final count = await _db.update(
        'call_logs',
        {...callLog.toEditableMap(), 'updated_at': _now().toDb()},
        where: 'id = ?',
        whereArgs: [callLog.id],
      );
      _requireOne(count);
    }).guard();
  }

  /// Links (or unlinks with `null`) a call to a lead.
  Future<void> linkToLead(int callLogId, int? leadId) {
    return Future(() async {
      final count = await _db.update(
        'call_logs',
        {'lead_id': leadId, 'updated_at': _now().toDb()},
        where: 'id = ?',
        whereArgs: [callLogId],
      );
      _requireOne(count);
    }).guard();
  }

  /// Recordings linked to this call keep existing (`call_log_id` → NULL).
  Future<void> deleteCallLog(int id) {
    return Future(() async {
      final count = await _db.delete(
        'call_logs',
        where: 'id = ?',
        whereArgs: [id],
      );
      _requireOne(count);
    }).guard();
  }

  /// Newest first.
  Future<List<CallLog>> listForLead(int leadId) {
    return _list(where: 'lead_id = ?', whereArgs: [leadId]);
  }

  /// Newest first across all leads.
  Future<List<CallLog>> listRecent({int limit = 50}) {
    return _list(limit: limit);
  }

  Future<List<CallLog>> _list({
    String? where,
    List<Object?>? whereArgs,
    int? limit,
  }) {
    return Future(() async {
      final rows = await _db.query(
        'call_logs',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'called_at DESC, id DESC',
        limit: limit,
      );
      return rows.map(CallLog.fromMap).toList();
    }).guard();
  }

  static void _requireOne(int count) {
    if (count != 1) {
      throw AppException(
        message: 'This call record no longer exists.',
        type: ErrorType.database,
      );
    }
  }
}

@riverpod
CallLogRepository callLogRepository(Ref ref) =>
    CallLogRepository(ref.watch(appDatabaseProvider).requireValue);
