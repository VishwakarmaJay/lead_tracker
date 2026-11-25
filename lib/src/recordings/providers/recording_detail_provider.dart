import 'dart:io';

import 'package:lead_tracker/src/leads/providers/lead_refresh.dart';
import 'package:lead_tracker/src/recordings/data/call_recording_repository.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';
import 'package:lead_tracker/src/recordings/data/recording_storage.dart';
import 'package:lead_tracker/src/recordings/services/recording_import_service.dart';
import 'package:lead_tracker/src/shared/providers/busy_operations_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recording_detail_provider.g.dart';

/// One recording for the player screen; null if it was deleted.
@riverpod
class RecordingDetail extends _$RecordingDetail {
  @override
  Future<CallRecording?> build(int recordingId) =>
      ref.watch(callRecordingRepositoryProvider).getRecordingById(recordingId);

  Future<void> updateNotes(String? notes) async {
    final trimmed = notes?.trim();
    await ref
        .read(callRecordingRepositoryProvider)
        .updateNotes(
          recordingId,
          trimmed == null || trimmed.isEmpty ? null : trimmed,
        );
    _refresh();
  }

  Future<void> linkToCall(int? callLogId) async {
    await ref
        .read(callRecordingRepositoryProvider)
        .linkToCallLog(recordingId, callLogId);
    _refresh();
  }

  /// Saves the duration the player read, if it wasn't known at import.
  Future<void> saveDuration(Duration duration) async {
    final recording = state.value;
    if (recording == null || recording.durationMs != null) {
      return;
    }
    await ref
        .read(callRecordingRepositoryProvider)
        .updateDuration(recordingId, duration.inMilliseconds);
    _refresh();
  }

  /// Deletes Lead Tracker's copy (row, then file). The original in Google
  /// Phone is never touched.
  Future<void> delete() async {
    final recording = state.value;
    if (recording == null) {
      return;
    }
    await ref
        .read(busyOperationsProvider.notifier)
        .track(
          () => ref
              .read(recordingImportServiceProvider)
              .deleteRecording(recording),
        );
    _refresh();
  }

  void _refresh() {
    final leadId = state.value?.leadId;
    ref
      ..refreshLeadViews(leadId: leadId)
      ..invalidateSelf();
  }
}

/// The recording's audio file on disk.
@riverpod
Future<File> recordingFile(Ref ref, String relativePath) =>
    ref.watch(recordingStorageProvider).resolve(relativePath);
