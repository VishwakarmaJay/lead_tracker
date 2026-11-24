import 'package:lead_tracker/core/database/db_value.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/future.dart';
import 'package:lead_tracker/core/instances/app_database_instance.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'lead_repository.g.dart';

/// All SQL for the `leads` table. Every method returns typed models and
/// reports failures as `AppException`.
///
/// Deleting is a **soft delete** (`deleted_at`). A lead with recordings can't
/// be hard-deleted (`ON DELETE RESTRICT`); a hard-delete flow with retention
/// rules comes later if ever needed.
class LeadRepository {
  LeadRepository(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Database _db;
  final DateTime Function() _now;

  Future<List<Lead>> searchLeads(LeadQuery query) {
    return Future(() async {
      final where = <String>[];
      final args = <Object?>[];
      if (!query.includeDeleted) {
        where.add('deleted_at IS NULL');
      }
      if (query.status != null) {
        where.add('status = ?');
        args.add(query.status!.dbValue);
      }
      if (query.temperature != null) {
        where.add('temperature = ?');
        args.add(query.temperature!.dbValue);
      }
      final text = query.text?.trim();
      if (text != null && text.isNotEmpty) {
        final pattern = '%${_escapeLike(text)}%';
        where.add(
          r"(name LIKE ? ESCAPE '\' OR company LIKE ? ESCAPE '\' "
          r"OR email LIKE ? ESCAPE '\' OR phone LIKE ? ESCAPE '\' "
          r"OR phone_normalized LIKE ? ESCAPE '\')",
        );
        args.addAll(List.filled(5, pattern));
      }
      final rows = await _db.query(
        'leads',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args,
        orderBy: 'name COLLATE NOCASE ASC, id ASC',
        limit: query.limit,
        offset: query.limit == null ? null : query.offset,
      );
      return rows.map(Lead.fromMap).toList();
    }).guard();
  }

  Future<Lead?> getLeadById(int id, {bool includeDeleted = false}) {
    return Future(() async {
      final rows = await _db.query(
        'leads',
        where: includeDeleted ? 'id = ?' : 'id = ? AND deleted_at IS NULL',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : Lead.fromMap(rows.first);
    }).guard();
  }

  /// Returns the new lead's id.
  Future<int> createLead(LeadDraft draft) {
    final now = _now().toDb();
    return _db.insert('leads', {
      ...draft.toMap(),
      'created_at': now,
      'updated_at': now,
    }).guard();
  }

  /// Inserts many leads in one transaction (all or nothing). Returns the ids
  /// in the same order as [drafts].
  Future<List<int>> createLeads(List<LeadDraft> drafts) {
    final now = _now().toDb();
    return _db.transaction((txn) async {
      final batch = txn.batch();
      for (final draft in drafts) {
        batch.insert('leads', {
          ...draft.toMap(),
          'created_at': now,
          'updated_at': now,
        });
      }
      final results = await batch.commit();
      return results.cast<int>();
    }).guard();
  }

  /// Saves every editable field of [lead].
  Future<void> updateLead(Lead lead) {
    return Future(() async {
      final count = await _db.update(
        'leads',
        {...lead.toEditableMap(), 'updated_at': _now().toDb()},
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [lead.id],
      );
      _requireOne(count);
    }).guard();
  }

  /// Soft delete. Call logs, follow-ups, and recordings stay intact.
  Future<void> deleteLead(int id) {
    return Future(() async {
      final now = _now().toDb();
      final count = await _db.update(
        'leads',
        {'deleted_at': now, 'updated_at': now},
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [id],
      );
      _requireOne(count);
    }).guard();
  }

  Future<void> restoreLead(int id) {
    return Future(() async {
      final count = await _db.update(
        'leads',
        {'deleted_at': null, 'updated_at': _now().toDb()},
        where: 'id = ? AND deleted_at IS NOT NULL',
        whereArgs: [id],
      );
      _requireOne(count);
    }).guard();
  }

  /// All active leads with this E.164 number. Several leads may legitimately
  /// share a number, so callers must handle more than one match.
  Future<List<Lead>> findByNormalizedPhone(String normalizedPhone) {
    return Future(() async {
      final rows = await _db.query(
        'leads',
        where: 'phone_normalized = ? AND deleted_at IS NULL',
        whereArgs: [normalizedPhone],
        orderBy: 'id ASC',
      );
      return rows.map(Lead.fromMap).toList();
    }).guard();
  }

  /// Normalised phone → names of active leads with that number. Used by the
  /// import preview to flag numbers that are already saved.
  Future<Map<String, List<String>>> activeNamesByNormalizedPhone() {
    return Future(() async {
      final rows = await _db.query(
        'leads',
        columns: ['phone_normalized', 'name'],
        where: 'phone_normalized IS NOT NULL AND deleted_at IS NULL',
        orderBy: 'id ASC',
      );
      final index = <String, List<String>>{};
      for (final row in rows) {
        index
            .putIfAbsent(row['phone_normalized']! as String, () => [])
            .add(row['name']! as String);
      }
      return index;
    }).guard();
  }

  static String _escapeLike(String text) => text
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  static void _requireOne(int count) {
    if (count != 1) {
      throw AppException(
        message: 'This lead no longer exists.',
        type: ErrorType.database,
      );
    }
  }
}

@riverpod
LeadRepository leadRepository(Ref ref) =>
    LeadRepository(ref.watch(appDatabaseProvider).requireValue);
