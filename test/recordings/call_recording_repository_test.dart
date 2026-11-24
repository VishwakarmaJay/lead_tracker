import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/future.dart';
import 'package:lead_tracker/src/calls/data/call_log_repository.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/recordings/data/call_recording_repository.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late TestClock clock;
  late CallRecordingRepository repo;
  late int leadId;

  setUp(() async {
    clock = TestClock();
    db = await openTestDatabase(now: clock.call);
    repo = CallRecordingRepository(db, now: clock.call);
    leadId = await insertLead(db);
  });

  CallRecordingDraft draft({String sha = 'aa11', int? callLogId}) {
    return CallRecordingDraft(
      leadId: leadId,
      callLogId: callLogId,
      originalFilename: 'Call with Asha.m4a',
      storedFilename: 'f3c1.m4a',
      relativePath: 'recordings/lead_$leadId/f3c1.m4a',
      mimeType: 'audio/mp4',
      fileSizeBytes: 2048,
      sha256: sha,
      importSource: RecordingImportSource.googlePhoneShare,
    );
  }

  test('creates, finds by checksum, and lists for a lead', () async {
    final id = await repo.createRecording(draft());

    final byId = (await repo.getRecordingById(id))!;
    expect(byId.relativePath, 'recordings/lead_$leadId/f3c1.m4a');
    expect(byId.importSource, RecordingImportSource.googlePhoneShare);
    expect(byId.importedAt, clock.current);

    expect((await repo.findBySha256('aa11'))!.id, id);
    expect(await repo.findBySha256('other'), isNull);
    expect(await repo.listForLead(leadId), hasLength(1));
  });

  test('rejects a second import of the same file (SHA-256 unique)', () async {
    await repo.createRecording(draft());
    expect(
      repo.createRecording(draft()),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'This record already exists.',
        ),
      ),
    );
  });

  test(
    'a lead with recordings cannot be removed (ON DELETE RESTRICT)',
    () async {
      await repo.createRecording(draft());
      expect(
        hardDeleteLead(db, leadId).guard(),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            'This record is still linked to other data.',
          ),
        ),
      );
    },
  );

  test('deleting the linked call keeps the recording (SET NULL)', () async {
    final callId = await CallLogRepository(
      db,
    ).createCallLog(CallLogDraft(leadId: leadId, calledAt: clock.current));
    final id = await repo.createRecording(draft(callLogId: callId));

    await CallLogRepository(db).deleteCallLog(callId);

    final recording = (await repo.getRecordingById(id))!;
    expect(recording.callLogId, isNull);
  });

  test('link to a call, update notes, delete the row', () async {
    final callId = await CallLogRepository(
      db,
    ).createCallLog(CallLogDraft(leadId: leadId, calledAt: clock.current));
    final id = await repo.createRecording(draft());

    await repo.linkToCallLog(id, callId);
    await repo.updateNotes(id, 'Pricing discussed');
    final saved = (await repo.getRecordingById(id))!;
    expect(saved.callLogId, callId);
    expect(saved.notes, 'Pricing discussed');

    await repo.deleteRecordingRow(id);
    expect(await repo.getRecordingById(id), isNull);
  });
}
