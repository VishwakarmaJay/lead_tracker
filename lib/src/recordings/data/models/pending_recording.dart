import 'package:flutter/foundation.dart';
import 'package:lead_tracker/core/instances/share_bridge.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';

/// An audio file waiting to be attached to a lead: either shared in (Google
/// Phone) or picked with the file picker.
@immutable
class PendingRecording {
  const PendingRecording({
    required this.path,
    required this.origin,
    this.displayName,
    this.mimeType,
    this.sizeBytes,
    this.shareItem,
  });

  factory PendingRecording.fromShare(SharedFilePayload item) {
    return PendingRecording(
      path: item.cachePath!,
      origin: RecordingImportSource.googlePhoneShare,
      displayName: item.displayName,
      mimeType: item.mimeType,
      sizeBytes: item.sizeBytes,
      shareItem: item,
    );
  }

  /// Absolute path of the temporary copy (share inbox or picker cache).
  final String path;
  final RecordingImportSource origin;

  /// Shown to the user only; never used as a path.
  final String? displayName;
  final String? mimeType;
  final int? sizeBytes;

  /// The inbox entry to remove once imported (shares only).
  final SharedFilePayload? shareItem;
}
