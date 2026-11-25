import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/leads/providers/lead_timeline_provider.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';

CallLog _call(int id, DateTime at) => CallLog(
  id: id,
  source: CallSource.manual,
  callType: CallType.outgoing,
  durationSeconds: 0,
  calledAt: at,
  createdAt: at,
  updatedAt: at,
);

CallRecording _recording(int id, DateTime importedAt, {int? callLogId}) =>
    CallRecording(
      id: id,
      leadId: 1,
      callLogId: callLogId,
      storedFilename: '$id.m4a',
      relativePath: 'recordings/lead_1/$id.m4a',
      mimeType: 'audio/mp4',
      fileSizeBytes: 1,
      sha256: '$id',
      importSource: RecordingImportSource.googlePhoneShare,
      importedAt: importedAt,
    );

void main() {
  test('newest first; a linked recording sits just above its call', () {
    final day = DateTime.utc(2026, 11, 24);
    final entries = buildTimeline(
      [
        _call(1, day.add(const Duration(hours: 9))),
        _call(2, day.add(const Duration(hours: 15))),
      ],
      [
        // Imported in the evening, but from the 9 am call.
        _recording(10, day.add(const Duration(hours: 20)), callLogId: 1),
        // Not linked: placed at its import time.
        _recording(11, day.add(const Duration(hours: 12))),
      ],
    );

    String describe(TimelineEntry entry) => switch (entry) {
      TimelineCall(:final call, :final hasRecording) =>
        'call ${call.id}${hasRecording ? ' (rec)' : ''}',
      TimelineRecording(:final recording) => 'recording ${recording.id}',
    };

    expect(entries.map(describe), [
      'call 2',
      'recording 11',
      'recording 10',
      'call 1 (rec)',
    ]);
  });
}
