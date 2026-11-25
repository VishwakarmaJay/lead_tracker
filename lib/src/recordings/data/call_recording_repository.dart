import 'package:lead_tracker/core/database/db_value.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/future.dart';
import 'package:lead_tracker/core/instances/app_database_instance.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'call_recording_repository.g.dart';

/// All SQL for `call_recordings`. Only metadata — moving and deleting the
/// audio files is the recording import service's job (Milestone 4).
class CallRecordingRepository {
  CallRecordingRepository(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Database _db;
  final DateTime Function() _now;

  /// Fails with "already exists" when the SHA-256 is already imported.
  Future<int> createRecording(CallRecordingDraft draft) {
    return _db.insert('call_recordings', {
      ...draft.toMap(),
      'imported_at': _now().toDb(),
    }).guard();
  }

  Future<CallRecording?> getRecordingById(int id) => _single('id = ?', [id]);

  /// Duplicate check before importing a file.
  Future<CallRecording?> findBySha256(String sha256) =>
      _single('sha256 = ?', [sha256]);

  /// Newest first.
  Future<List<CallRecording>> listForLead(int leadId) {
    return Future(() async {
      final rows = await _db.query(
        'call_recordings',
        where: 'lead_id = ?',
        whereArgs: [leadId],
        orderBy: 'imported_at DESC, id DESC',
      );
      return rows.map(CallRecording.fromMap).toList();
    }).guard();
  }

  Future<void> linkToCallLog(int id, int? callLogId) =>
      _update(id, {'call_log_id': callLogId});

  Future<void> updateNotes(int id, String? notes) =>
      _update(id, {'notes': notes});

  /// Stores the duration once the player has read it.
  Future<void> updateDuration(int id, int durationMs) =>
      _update(id, {'duration_ms': durationMs});

  /// Deletes the metadata row only.
  Future<void> deleteRecordingRow(int id) {
    return Future(() async {
      final count = await _db.delete(
        'call_recordings',
        where: 'id = ?',
        whereArgs: [id],
      );
      _requireOne(count);
    }).guard();
  }

  Future<CallRecording?> _single(String where, List<Object?> args) {
    return Future(() async {
      final rows = await _db.query(
        'call_recordings',
        where: where,
        whereArgs: args,
        limit: 1,
      );
      return rows.isEmpty ? null : CallRecording.fromMap(rows.first);
    }).guard();
  }

  Future<void> _update(int id, Map<String, Object?> values) {
    return Future(() async {
      final count = await _db.update(
        'call_recordings',
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
      _requireOne(count);
    }).guard();
  }

  static void _requireOne(int count) {
    if (count != 1) {
      throw AppException(
        message: 'This recording no longer exists.',
        type: ErrorType.database,
      );
    }
  }
}

@riverpod
CallRecordingRepository callRecordingRepository(Ref ref) =>
    CallRecordingRepository(ref.watch(appDatabaseProvider).requireValue);
