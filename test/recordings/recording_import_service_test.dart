import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/src/recordings/data/call_recording_repository.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';
import 'package:lead_tracker/src/recordings/services/recording_import_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';
import 'recording_test_env.dart';

void main() {
  late Database db;
  late RecordingTestEnv env;
  late CallRecordingRepository repo;
  late int leadId;
  var ids = 0;

  RecordingImportService service({
    Duration? probe = const Duration(seconds: 95),
  }) {
    return RecordingImportService(
      repository: repo,
      storage: env.storage,
      probe: fixedProbe(probe),
      newId: () => 'rec${++ids}',
    );
  }

  setUp(() async {
    db = await openTestDatabase();
    env = await RecordingTestEnv.create();
    repo = CallRecordingRepository(db);
    leadId = await insertLead(db);
  });

  test('copies into recordings/lead_<id>/ and saves the metadata', () async {
    final bytes = List<int>.generate(4096, (i) => i % 251);
    final file = await env.shared('Call recording Asha.m4a', bytes);

    final result = await service().importFile(
      file,
      leadId: leadId,
      notes: '  Discussed pricing  ',
    );

    expect(result, isA<RecordingImported>());
    final imported = result as RecordingImported;
    final recording = imported.recording;
    expect(imported.playable, isTrue);
    expect(recording.leadId, leadId);
    expect(recording.storedFilename, 'rec1.m4a');
    expect(
      recording.relativePath,
      p.join('recordings', 'lead_$leadId', 'rec1.m4a'),
    );
    expect(recording.mimeType, 'audio/mp4');
    expect(recording.fileSizeBytes, 4096);
    expect(recording.sha256, sha256Of(bytes));
    expect(recording.durationMs, 95000);
    expect(recording.originalFilename, 'Call recording Asha.m4a');
    expect(recording.importSource, RecordingImportSource.googlePhoneShare);
    expect(recording.notes, 'Discussed pricing');

    final stored = await env.storage.resolve(recording.relativePath);
    expect(await stored.readAsBytes(), bytes);
    // The service never deletes the original; the caller does after success.
    expect(File(file.path).existsSync(), isTrue);
    expect(env.storedFiles(), [recording.relativePath]);
  });

  test('the same file twice is detected and nothing new is saved', () async {
    final bytes = List<int>.filled(1000, 7);
    final first = await env.shared('a.m4a', bytes);
    final again = await env.shared('b.m4a', bytes);

    final firstResult = await service().importFile(first, leadId: leadId);
    final secondResult = await service().importFile(again, leadId: leadId);

    expect(secondResult, isA<RecordingAlreadyImported>());
    expect(
      (secondResult as RecordingAlreadyImported).existing.id,
      (firstResult as RecordingImported).recording.id,
    );
    expect(env.storedFiles(), hasLength(1));
    expect(await repo.listForLead(leadId), hasLength(1));
  });

  test('a file the player cannot open is still saved, flagged', () async {
    final file = await env.shared('odd.amr', [1, 2, 3], mimeType: 'audio/amr');
    final result = await service(probe: null).importFile(file, leadId: leadId);

    final imported = result as RecordingImported;
    expect(imported.playable, isFalse);
    expect(imported.recording.durationMs, isNull);
    expect(imported.recording.storedFilename, endsWith('.amr'));
  });

  test('rejects missing, empty, and non-audio files without saving', () async {
    final isFileError = throwsA(
      isA<AppException>().having((e) => e.type, 'type', ErrorType.file),
    );

    final missing = await env.shared('gone.m4a', [1]);
    await File(missing.path).delete();
    await expectLater(
      service().importFile(missing, leadId: leadId),
      isFileError,
    );

    final empty = await env.shared('empty.m4a', const []);
    await expectLater(service().importFile(empty, leadId: leadId), isFileError);

    final photo = await env.shared('photo.png', [1, 2], mimeType: 'image/png');
    await expectLater(service().importFile(photo, leadId: leadId), isFileError);

    expect(env.storedFiles(), isEmpty);
    expect(await repo.listForLead(leadId), isEmpty);
  });

  test(
    'if saving the row fails, the copy is removed and the original kept',
    () async {
      await db.execute(
        'CREATE TRIGGER fail_recording BEFORE INSERT ON call_recordings '
        "BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      final file = await env.shared('a.m4a', [9, 9, 9]);

      await expectLater(
        service().importFile(file, leadId: leadId),
        throwsA(isA<AppException>()),
      );

      expect(env.storedFiles(), isEmpty);
      expect(File(file.path).existsSync(), isTrue);
    },
  );

  test('a lead id that does not exist is rejected, copy removed', () async {
    final file = await env.shared('a.m4a', [1, 2, 3]);
    await expectLater(
      service().importFile(file, leadId: 999),
      throwsA(isA<AppException>()),
    );
    expect(env.storedFiles(), isEmpty);
  });

  test('delete removes the row and the file', () async {
    final file = await env.shared('a.m4a', [4, 5, 6]);
    final recording =
        ((await service().importFile(file, leadId: leadId))
                as RecordingImported)
            .recording;

    await service().deleteRecording(recording);

    expect(await repo.getRecordingById(recording.id), isNull);
    expect(env.storedFiles(), isEmpty);
  });
}
