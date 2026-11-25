import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/instances/share_bridge.dart';
import 'package:lead_tracker/src/calls/data/call_log_repository.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/leads/providers/lead_timeline_provider.dart';
import 'package:lead_tracker/src/recordings/data/audio_probe.dart';
import 'package:lead_tracker/src/recordings/data/models/pending_recording.dart';
import 'package:lead_tracker/src/recordings/data/recording_storage.dart';
import 'package:lead_tracker/src/recordings/providers/recording_detail_provider.dart';
import 'package:lead_tracker/src/recordings/providers/recording_import_provider.dart';
import 'package:lead_tracker/src/recordings/services/recording_import_service.dart';
import 'package:lead_tracker/src/shared/providers/busy_operations_provider.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_container.dart';
import 'recording_test_env.dart';

/// An inbox entry for a file already written by [RecordingTestEnv.shared].
PendingRecording _fromInbox(PendingRecording file) {
  return PendingRecording.fromShare(
    SharedFilePayload(
      id: file.path,
      receivedAt: DateTime.utc(2026, 11, 24),
      cachePath: file.path,
      displayName: file.displayName,
      mimeType: file.mimeType,
      sizeBytes: File(file.path).lengthSync(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> deletedFromInbox;

  setUp(() {
    deletedFromInbox = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const methods = MethodChannel('lead_tracker/share');
    const events = MethodChannel('lead_tracker/share/events');
    messenger
      ..setMockMethodCallHandler(methods, (call) async {
        if (call.method == 'deleteCached') {
          deletedFromInbox.add((call.arguments as Map)['path'] as String);
          return true;
        }
        return const <Object?>[];
      })
      ..setMockMethodCallHandler(events, (call) async => null);
    addTearDown(() {
      messenger
        ..setMockMethodCallHandler(methods, null)
        ..setMockMethodCallHandler(events, null);
    });
  });

  Future<(ProviderContainer, RecordingTestEnv, int)> setUpImport() async {
    final env = await RecordingTestEnv.create();
    final (container, db) = await createTestContainer(
      overrides: [
        recordingStorageProvider.overrideWithValue(env.storage),
        audioProbeProvider.overrideWithValue(
          fixedProbe(const Duration(seconds: 30)),
        ),
      ],
    );
    final leadId = await insertLead(db);
    return (container, env, leadId);
  }

  test(
    'saving a shared recording imports it and clears the inbox copy',
    () async {
      final (container, env, leadId) = await setUpImport();
      container
        ..listen(recordingImportControllerProvider, (_, _) {})
        ..listen(leadTimelineProvider(leadId), (_, _) {});
      expect(
        await container.read(leadTimelineProvider(leadId).future),
        isEmpty,
      );

      final file = await env.shared('call.m4a', [1, 2, 3, 4]);
      final result = await container
          .read(recordingImportControllerProvider.notifier)
          .save(_fromInbox(file), leadId: leadId);

      expect(result, isA<RecordingImported>());
      expect(deletedFromInbox, [file.path]);
      expect(container.read(busyOperationsProvider), 0);
      final timeline = await container.read(
        leadTimelineProvider(leadId).future,
      );
      expect(timeline.single, isA<TimelineRecording>());
    },
  );

  test('a duplicate keeps the inbox copy for the user to decide', () async {
    final (container, env, leadId) = await setUpImport();
    container.listen(recordingImportControllerProvider, (_, _) {});
    final controller = container.read(
      recordingImportControllerProvider.notifier,
    );

    await controller.save(
      _fromInbox(await env.shared('a.m4a', [7, 7, 7])),
      leadId: leadId,
    );
    deletedFromInbox.clear();

    final result = await controller.save(
      _fromInbox(await env.shared('b.m4a', [7, 7, 7])),
      leadId: leadId,
    );

    expect(result, isA<RecordingAlreadyImported>());
    expect(deletedFromInbox, isEmpty);
  });

  test('player screen: notes, call link, duration, delete', () async {
    final (container, env, leadId) = await setUpImport();
    final file = await env.shared('a.m4a', [1, 2, 3]);
    final imported = await container
        .read(recordingImportServiceProvider)
        .importFile(file, leadId: leadId);
    final recording = (imported as RecordingImported).recording;

    final callId = await container
        .read(callLogRepositoryProvider)
        .createCallLog(
          CallLogDraft(leadId: leadId, calledAt: DateTime.utc(2026, 11, 24)),
        );

    final detail = recordingDetailProvider(recording.id);
    container.listen(detail, (_, _) {});
    await container.read(detail.future);
    final notifier = container.read(detail.notifier);

    await notifier.updateNotes('  Budget agreed  ');
    await notifier.linkToCall(callId);
    var saved = (await container.read(detail.future))!;
    expect(saved.notes, 'Budget agreed');
    expect(saved.callLogId, callId);

    // A duration known at import is not overwritten.
    await notifier.saveDuration(const Duration(minutes: 9));
    saved = (await container.read(detail.future))!;
    expect(saved.durationMs, 30000);

    await notifier.delete();
    expect(await container.read(detail.future), isNull);
    expect(env.storedFiles(), isEmpty);
  });
}
