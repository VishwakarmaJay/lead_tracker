import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/src/calls/data/call_log_repository.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late TestClock clock;
  late CallLogRepository repo;
  late int leadId;

  setUp(() async {
    clock = TestClock();
    db = await openTestDatabase(now: clock.call);
    repo = CallLogRepository(db, now: clock.call);
    leadId = await insertLead(db);
  });

  test('creates a manual call log and reads it back', () async {
    final id = await repo.createCallLog(
      CallLogDraft(
        leadId: leadId,
        calledAt: clock.current,
        callType: CallType.outgoing,
        durationSeconds: 125,
        disposition: CallDisposition.followUp,
        summary: 'Asked for portfolio',
      ),
    );

    final log = (await repo.getCallLogById(id))!;
    expect(log.source, CallSource.manual);
    expect(log.leadId, leadId);
    expect(log.callType, CallType.outgoing);
    expect(log.durationSeconds, 125);
    expect(log.disposition, CallDisposition.followUp);
    expect(log.summary, 'Asked for portfolio');
    expect(log.calledAt, clock.current);
  });

  test(
    'allows many manual logs but rejects a duplicate system call id',
    () async {
      final now = clock.current;
      await repo.createCallLog(CallLogDraft(calledAt: now));
      await repo.createCallLog(CallLogDraft(calledAt: now));

      final system = CallLogDraft(
        calledAt: now,
        source: CallSource.androidCallLog,
        sourceRecordId: '42',
      );
      await repo.createCallLog(system);
      expect(
        repo.createCallLog(system),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            'This record already exists.',
          ),
        ),
      );
    },
  );

  test("lists a lead's calls and recent calls newest first", () async {
    final base = clock.current;
    await repo.createCallLog(CallLogDraft(leadId: leadId, calledAt: base));
    await repo.createCallLog(
      CallLogDraft(
        leadId: leadId,
        calledAt: base.add(const Duration(hours: 2)),
        summary: 'second',
      ),
    );
    await repo.createCallLog(
      CallLogDraft(calledAt: base.add(const Duration(hours: 1))),
    );

    final forLead = await repo.listForLead(leadId);
    expect(forLead.map((c) => c.summary), ['second', null]);

    final recent = await repo.listRecent(limit: 2);
    expect(recent, hasLength(2));
    expect(recent.first.summary, 'second');
  });

  test('update and link/unlink', () async {
    final id = await repo.createCallLog(CallLogDraft(calledAt: clock.current));
    final log = (await repo.getCallLogById(id))!;

    await repo.updateCallLog(
      log.copyWith(
        disposition: () => CallDisposition.interested,
        summary: () => 'Keen',
      ),
    );
    await repo.linkToLead(id, leadId);
    var saved = (await repo.getCallLogById(id))!;
    expect(saved.disposition, CallDisposition.interested);
    expect(saved.leadId, leadId);

    await repo.linkToLead(id, null);
    saved = (await repo.getCallLogById(id))!;
    expect(saved.leadId, isNull);
  });

  test(
    'a removed lead leaves its calls unlinked (ON DELETE SET NULL)',
    () async {
      final id = await repo.createCallLog(
        CallLogDraft(leadId: leadId, calledAt: clock.current),
      );
      await hardDeleteLead(db, leadId);
      expect((await repo.getCallLogById(id))!.leadId, isNull);
    },
  );

  test('deleting a missing call log fails clearly', () {
    expect(repo.deleteCallLog(999), throwsA(isA<AppException>()));
  });
}
