import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/src/follow_ups/data/follow_up_repository.dart';
import 'package:lead_tracker/src/follow_ups/data/models/follow_up.dart';
import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late TestClock clock;
  late FollowUpRepository repo;
  late int leadId;

  setUp(() async {
    clock = TestClock();
    db = await openTestDatabase(now: clock.call);
    repo = FollowUpRepository(db, now: clock.call);
    leadId = await insertLead(db);
  });

  Future<int> add(String title, Duration fromNow, {int? lead}) {
    return repo.createFollowUp(
      FollowUpDraft(
        leadId: lead ?? leadId,
        title: title,
        dueAt: clock.current.add(fromNow),
      ),
    );
  }

  test('creates a pending follow-up', () async {
    final id = await add('Send portfolio', const Duration(days: 1));
    final followUp = (await repo.getFollowUpById(id))!;
    expect(followUp.status, FollowUpStatus.pending);
    expect(followUp.title, 'Send portfolio');
    expect(followUp.completedAt, isNull);
  });

  test('listPending is soonest first and can stop at a cut-off', () async {
    await add('later', const Duration(days: 3));
    await add('overdue', const Duration(days: -1));
    await add('today', const Duration(hours: 2));

    final all = await repo.listPending();
    expect(all.map((f) => f.title), ['overdue', 'today', 'later']);

    final dueSoon = await repo.listPending(
      dueBefore: clock.current.add(const Duration(days: 1)),
    );
    expect(dueSoon.map((f) => f.title), ['overdue', 'today']);
    expect(dueSoon.first.isOverdueAt(clock.current), isTrue);
  });

  test('complete, cancel and reschedule only work on pending', () async {
    final a = await add('a', const Duration(days: 1));
    final b = await add('b', const Duration(days: 1));

    clock.advance(const Duration(minutes: 5));
    await repo.complete(a);
    final done = (await repo.getFollowUpById(a))!;
    expect(done.status, FollowUpStatus.completed);
    expect(done.completedAt, clock.current);

    await repo.cancel(b);
    expect((await repo.getFollowUpById(b))!.status, FollowUpStatus.cancelled);

    final notPending = throwsA(isA<AppException>());
    expect(repo.complete(a), notPending);
    expect(repo.reschedule(b, clock.current), notPending);

    expect(
      (await repo.listClosed(status: FollowUpStatus.completed)).single.id,
      a,
    );
    expect(await repo.listPending(), isEmpty);
  });

  test('reschedule and edit a pending follow-up', () async {
    final id = await add('call back', const Duration(days: 1));
    final newDue = clock.current.add(const Duration(days: 5));

    await repo.reschedule(id, newDue);
    var saved = (await repo.getFollowUpById(id))!;
    expect(saved.dueAt, newDue);

    await repo.updateFollowUp(saved.copyWith(note: () => 'after 6pm'));
    saved = (await repo.getFollowUpById(id))!;
    expect(saved.note, 'after 6pm');
  });

  test('stores and clears the notification id', () async {
    final id = await add('x', const Duration(days: 1));
    await repo.setNotificationId(id, 7);
    expect((await repo.getFollowUpById(id))!.notificationId, 7);
    await repo.setNotificationId(id, null);
    expect((await repo.getFollowUpById(id))!.notificationId, isNull);
  });

  test('follow-ups of a soft-deleted lead are hidden from lists', () async {
    final other = await insertLead(db, name: 'Other');
    await add('mine', const Duration(days: 1));
    await add('theirs', const Duration(days: 1), lead: other);

    await LeadRepository(db).deleteLead(other);

    expect((await repo.listPending()).map((f) => f.title), ['mine']);
  });

  test('removing a lead removes its follow-ups (ON DELETE CASCADE)', () async {
    final id = await add('x', const Duration(days: 1));
    await hardDeleteLead(db, leadId);
    expect(await repo.getFollowUpById(id), isNull);
  });
}
