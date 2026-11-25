import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';
import 'package:lead_tracker/src/recordings/data/models/pending_recording.dart';
import 'package:lead_tracker/src/recordings/data/recording_storage.dart';
import 'package:path/path.dart' as p;

/// Temp folders standing in for the app documents dir and the share inbox.
class RecordingTestEnv {
  RecordingTestEnv._(this.documents, this.inbox);

  final Directory documents;
  final Directory inbox;

  static Future<RecordingTestEnv> create() async {
    final root = await Directory.systemTemp.createTemp('lead_tracker_rec_');
    addTearDown(() => root.delete(recursive: true));
    final documents = await Directory(p.join(root.path, 'docs')).create();
    final inbox = await Directory(p.join(root.path, 'inbox')).create();
    return RecordingTestEnv._(documents, inbox);
  }

  RecordingStorage get storage => RecordingStorage(() async => documents);

  /// Writes a fake audio file into the inbox.
  Future<PendingRecording> shared(
    String name,
    List<int> bytes, {
    String mimeType = 'audio/mp4',
    RecordingImportSource origin = RecordingImportSource.googlePhoneShare,
  }) async {
    final file = File(p.join(inbox.path, name));
    await file.writeAsBytes(bytes);
    return PendingRecording(
      path: file.path,
      origin: origin,
      displayName: name,
      mimeType: mimeType,
      sizeBytes: bytes.length,
    );
  }

  /// Every file under `recordings/`, relative to the documents dir.
  List<String> storedFiles() {
    final dir = Directory(p.join(documents.path, 'recordings'));
    if (!dir.existsSync()) {
      return const [];
    }
    return [
      for (final entity in dir.listSync(recursive: true))
        if (entity is File) p.relative(entity.path, from: documents.path),
    ]..sort();
  }
}

String sha256Of(List<int> bytes) => sha256.convert(bytes).toString();

/// Probe that reports a fixed duration (or "can't play" with null).
Future<Duration?> Function(String) fixedProbe(Duration? duration) =>
    (_) async => duration;
