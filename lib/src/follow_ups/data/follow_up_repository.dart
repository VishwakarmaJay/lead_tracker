import 'package:lead_tracker/core/database/db_value.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/future.dart';
import 'package:lead_tracker/core/instances/app_database_instance.dart';
import 'package:lead_tracker/src/follow_ups/data/models/follow_up.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'follow_up_repository.g.dart';

/// All SQL for `follow_ups`. Lists hide follow-ups of soft-deleted leads.
class FollowUpRepository {
  FollowUpRepository(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Database _db;
  final DateTime Function() _now;

  static const _activeLeadJoin =
      'SELECT f.* FROM follow_ups f JOIN leads l ON l.id = f.lead_id '
      'WHERE l.deleted_at IS NULL';

  Future<int> createFollowUp(FollowUpDraft draft) {
    final now = _now().toDb();
    return _db.insert('follow_ups', {
      ...draft.toMap(),
      'status': FollowUpStatus.pending.dbValue,
      'created_at': now,
      'updated_at': now,
    }).guard();
  }

  Future<FollowUp?> getFollowUpById(int id) {
    return Future(() async {
      final rows = await _db.query(
        'follow_ups',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : FollowUp.fromMap(rows.first);
    }).guard();
  }

  /// Saves title, note, and due time of a pending follow-up.
  Future<void> updateFollowUp(FollowUp followUp) {
    return _updatePending(followUp.id, {
      'title': followUp.title,
      'note': followUp.note,
      'due_at': followUp.dueAt.toDb(),
    });
  }

  Future<void> reschedule(int id, DateTime dueAt) =>
      _updatePending(id, {'due_at': dueAt.toDb()});

  Future<void> complete(int id) {
    final now = _now().toDb();
    return _updatePending(id, {
      'status': FollowUpStatus.completed.dbValue,
      'completed_at': now,
    });
  }

  Future<void> cancel(int id) =>
      _updatePending(id, {'status': FollowUpStatus.cancelled.dbValue});

  /// Stores (or clears) the scheduled notification id.
  Future<void> setNotificationId(int id, int? notificationId) {
    return Future(() async {
      final count = await _db.update(
        'follow_ups',
        {'notification_id': notificationId, 'updated_at': _now().toDb()},
        where: 'id = ?',
        whereArgs: [id],
      );
      _requireOne(count);
    }).guard();
  }

  /// All follow-ups of one lead, soonest first.
  Future<List<FollowUp>> listForLead(int leadId) {
    return Future(() async {
      final rows = await _db.query(
        'follow_ups',
        where: 'lead_id = ?',
        whereArgs: [leadId],
        orderBy: 'due_at ASC, id ASC',
      );
      return rows.map(FollowUp.fromMap).toList();
    }).guard();
  }

  /// Pending follow-ups due before [dueBefore] (all pending when null),
  /// soonest first. Overdue and "due today" lists are built from this.
  Future<List<FollowUp>> listPending({DateTime? dueBefore, int? limit}) {
    return Future(() async {
      final args = <Object?>[FollowUpStatus.pending.dbValue];
      var sql = '$_activeLeadJoin AND f.status = ?';
      if (dueBefore != null) {
        sql += ' AND f.due_at < ?';
        args.add(dueBefore.toDb());
      }
      sql += ' ORDER BY f.due_at ASC, f.id ASC';
      if (limit != null) {
        sql += ' LIMIT ?';
        args.add(limit);
      }
      final rows = await _db.rawQuery(sql, args);
      return rows.map(FollowUp.fromMap).toList();
    }).guard();
  }

  /// Completed or cancelled follow-ups, most recently changed first.
  Future<List<FollowUp>> listClosed({
    required FollowUpStatus status,
    int? limit,
  }) {
    return Future(() async {
      final args = <Object?>[status.dbValue];
      var sql =
          '$_activeLeadJoin AND f.status = ? '
          'ORDER BY f.updated_at DESC, f.id DESC';
      if (limit != null) {
        sql += ' LIMIT ?';
        args.add(limit);
      }
      final rows = await _db.rawQuery(sql, args);
      return rows.map(FollowUp.fromMap).toList();
    }).guard();
  }

  Future<void> _updatePending(int id, Map<String, Object?> values) {
    return Future(() async {
      final count = await _db.update(
        'follow_ups',
        {...values, 'updated_at': _now().toDb()},
        where: 'id = ? AND status = ?',
        whereArgs: [id, FollowUpStatus.pending.dbValue],
      );
      if (count != 1) {
        throw AppException(
          message: 'This follow-up is no longer pending.',
          type: ErrorType.database,
        );
      }
    }).guard();
  }

  static void _requireOne(int count) {
    if (count != 1) {
      throw AppException(
        message: 'This follow-up no longer exists.',
        type: ErrorType.database,
      );
    }
  }
}

@riverpod
FollowUpRepository followUpRepository(Ref ref) =>
    FollowUpRepository(ref.watch(appDatabaseProvider).requireValue);
