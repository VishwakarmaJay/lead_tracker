import 'package:lead_tracker/core/instances/file_picker_service.dart';
import 'package:lead_tracker/src/leads/providers/lead_refresh.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';
import 'package:lead_tracker/src/recordings/data/models/pending_recording.dart';
import 'package:lead_tracker/src/recordings/providers/shared_inbox_provider.dart';
import 'package:lead_tracker/src/recordings/services/recording_import_service.dart';
import 'package:lead_tracker/src/shared/providers/busy_operations_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recording_import_provider.g.dart';

/// Saves a pending recording to a lead (the "Save recording" screen).
@riverpod
class RecordingImportController extends _$RecordingImportController {
  @override
  bool build() => false; // true while saving

  /// Imports [file] for [leadId]. After a successful import the temporary
  /// copy is removed (share inbox entry or picker cache). On a duplicate or
  /// a failure it is kept, so nothing is lost.
  Future<RecordingImportResult> save(
    PendingRecording file, {
    required int leadId,
    int? callLogId,
    String? notes,
  }) async {
    state = true;
    try {
      final result = await ref
          .read(busyOperationsProvider.notifier)
          .track(
            () => ref
                .read(recordingImportServiceProvider)
                .importFile(
                  file,
                  leadId: leadId,
                  callLogId: callLogId,
                  notes: notes,
                ),
          );
      if (result is RecordingImported) {
        await discardSource(file);
        ref.refreshLeadViews(leadId: leadId);
      }
      return result;
    } finally {
      if (ref.mounted) {
        state = false;
      }
    }
  }

  /// Removes the temporary copy without importing it.
  Future<void> discardSource(PendingRecording file) async {
    final shareItem = file.shareItem;
    if (shareItem != null) {
      await ref.read(sharedInboxProvider.notifier).discard(shareItem);
    } else if (file.origin == RecordingImportSource.filePicker) {
      await ref.read(filePickerServiceProvider).clearTemporaryFiles();
    }
  }
}
