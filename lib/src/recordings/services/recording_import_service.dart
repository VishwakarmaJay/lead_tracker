import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/future.dart';
import 'package:lead_tracker/core/extension/log.dart';
import 'package:lead_tracker/src/recordings/data/audio_formats.dart';
import 'package:lead_tracker/src/recordings/data/audio_probe.dart';
import 'package:lead_tracker/src/recordings/data/call_recording_repository.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';
import 'package:lead_tracker/src/recordings/data/models/pending_recording.dart';
import 'package:lead_tracker/src/recordings/data/recording_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recording_import_service.g.dart';

sealed class RecordingImportResult {
  const RecordingImportResult();
}

@immutable
class RecordingImported extends RecordingImportResult {
  const RecordingImported({required this.recording, required this.playable});

  final CallRecording recording;

  /// False when this phone's player couldn't open the file. It is still
  /// saved — nothing the user shared is thrown away.
  final bool playable;
}

/// The same file (by SHA-256) was imported before. Nothing new was saved.
@immutable
class RecordingAlreadyImported extends RecordingImportResult {
  const RecordingAlreadyImported(this.existing);

  final CallRecording existing;
}

/// Attaches an audio file to a lead:
///
/// 1. check it exists, isn't empty or too large, and is a supported format;
/// 2. SHA-256 (streamed, background isolate) → stop if already imported;
/// 3. probe it with the player (duration; whether it plays);
/// 4. **copy** it to `recordings/lead_<id>/<generated>.<ext>`;
/// 5. insert the metadata row — if that fails, the copy is removed and the
///    original temporary file is still there to retry.
///
/// The service never deletes the original; the caller removes it from the
/// share inbox / picker cache only after a successful import.
class RecordingImportService {
  RecordingImportService({
    required CallRecordingRepository repository,
    required RecordingStorage storage,
    required AudioProbe probe,
    Future<String> Function(String path) checksum = sha256OfFile,
    String Function()? newId,
  }) : _repository = repository,
       _storage = storage,
       _probe = probe,
       _checksum = checksum,
       _newId = newId ?? _randomId;

  static const maxBytes = 200 * 1024 * 1024;

  final CallRecordingRepository _repository;
  final RecordingStorage _storage;
  final AudioProbe _probe;
  final Future<String> Function(String path) _checksum;
  final String Function() _newId;

  Future<RecordingImportResult> importFile(
    PendingRecording file, {
    required int leadId,
    int? callLogId,
    String? notes,
  }) async {
    final source = File(file.path);
    final size = await _sizeOf(source);
    if (size == 0) {
      throw _fileError('The recording file is empty.');
    }
    if (size > maxBytes) {
      throw _fileError('The recording is larger than 200 MB.');
    }
    final format = detectAudioFormat(
      mimeType: file.mimeType,
      fileName: file.displayName ?? file.path,
    );
    if (format == null) {
      throw _fileError(
        "This isn't an audio format Lead Tracker can import "
        '(${file.mimeType ?? 'unknown type'}).',
      );
    }

    final checksum = await _checksum(file.path).guard();
    final existing = await _repository.findBySha256(checksum);
    if (existing != null) {
      return RecordingAlreadyImported(existing);
    }

    final duration = await _probe(file.path);
    final storedFilename = '${_newId()}.${format.extension}';
    final relativePath = await _storage
        .copyIn(source: source, leadId: leadId, storedFilename: storedFilename)
        .guard();

    final int id;
    try {
      id = await _repository.createRecording(
        CallRecordingDraft(
          leadId: leadId,
          callLogId: callLogId,
          originalFilename: file.displayName,
          storedFilename: storedFilename,
          relativePath: relativePath,
          mimeType: format.mimeType,
          durationMs: duration?.inMilliseconds,
          fileSizeBytes: size,
          sha256: checksum,
          importSource: file.origin,
          notes: _clean(notes),
        ),
      );
    } on Exception {
      // The original is untouched, so the user can retry; drop our copy.
      await _storage
          .delete(relativePath)
          .guard()
          .onError<AppException>(
            (e, _) => 'Could not remove copy after failed save'.logWarning(),
          );
      rethrow;
    }

    final recording = await _repository.getRecordingById(id);
    return RecordingImported(recording: recording!, playable: duration != null);
  }

  /// Removes the metadata row, then the file. A leftover file (if the delete
  /// fails) is harmless and is cleaned up by the storage view (Milestone 7).
  Future<void> deleteRecording(CallRecording recording) async {
    await _repository.deleteRecordingRow(recording.id);
    try {
      await _storage.delete(recording.relativePath).guard();
    } on AppException {
      'Recording file could not be deleted; left for cleanup'.logWarning();
    }
  }

  Future<int> _sizeOf(File file) async {
    if (!file.existsSync()) {
      throw _fileError(
        'The recording file is missing. Share it from Google Phone again.',
      );
    }
    return file.length().guard();
  }

  static AppException _fileError(String message) =>
      AppException(message: message, type: ErrorType.file);

  static String? _clean(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _randomId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

@riverpod
RecordingImportService recordingImportService(Ref ref) =>
    RecordingImportService(
      repository: ref.watch(callRecordingRepositoryProvider),
      storage: ref.watch(recordingStorageProvider),
      probe: ref.watch(audioProbeProvider),
    );
