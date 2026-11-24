import 'package:flutter/foundation.dart';
import 'package:lead_tracker/core/database/db_value.dart';

enum RecordingImportSource implements DbValue {
  googlePhoneShare('google_phone_share'),
  filePicker('file_picker');

  const RecordingImportSource(this.dbValue);

  @override
  final String dbValue;
}

/// Metadata row in `call_recordings`. The audio itself is a file in
/// app-private storage at [relativePath] (relative to the documents dir).
@immutable
class CallRecording {
  const CallRecording({
    required this.id,
    required this.leadId,
    required this.storedFilename,
    required this.relativePath,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.sha256,
    required this.importSource,
    required this.importedAt,
    this.callLogId,
    this.originalFilename,
    this.durationMs,
    this.notes,
  });

  factory CallRecording.fromMap(Map<String, Object?> map) {
    return CallRecording(
      id: map['id']! as int,
      leadId: map['lead_id']! as int,
      callLogId: map['call_log_id'] as int?,
      originalFilename: map['original_filename'] as String?,
      storedFilename: map['stored_filename']! as String,
      relativePath: map['relative_path']! as String,
      mimeType: map['mime_type']! as String,
      durationMs: map['duration_ms'] as int?,
      fileSizeBytes: map['file_size_bytes']! as int,
      sha256: map['sha256']! as String,
      importSource: enumFromDb(
        RecordingImportSource.values,
        map['import_source'],
      ),
      importedAt: dateFromDb(map['imported_at']),
      notes: map['notes'] as String?,
    );
  }

  final int id;
  final int leadId;
  final int? callLogId;

  /// Display only — never used as a path.
  final String? originalFilename;
  final String storedFilename;
  final String relativePath;
  final String mimeType;
  final int? durationMs;
  final int fileSizeBytes;
  final String sha256;
  final RecordingImportSource importSource;
  final DateTime importedAt;
  final String? notes;
}

/// Data for a new recording row (the file must already be in place).
@immutable
class CallRecordingDraft {
  const CallRecordingDraft({
    required this.leadId,
    required this.storedFilename,
    required this.relativePath,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.sha256,
    required this.importSource,
    this.callLogId,
    this.originalFilename,
    this.durationMs,
    this.notes,
  });

  final int leadId;
  final int? callLogId;
  final String? originalFilename;
  final String storedFilename;
  final String relativePath;
  final String mimeType;
  final int? durationMs;
  final int fileSizeBytes;
  final String sha256;
  final RecordingImportSource importSource;
  final String? notes;

  Map<String, Object?> toMap() => {
    'lead_id': leadId,
    'call_log_id': callLogId,
    'original_filename': originalFilename,
    'stored_filename': storedFilename,
    'relative_path': relativePath,
    'mime_type': mimeType,
    'duration_ms': durationMs,
    'file_size_bytes': fileSizeBytes,
    'sha256': sha256,
    'import_source': importSource.dbValue,
    'notes': notes,
  };
}
