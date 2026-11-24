import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_bridge.g.dart';

/// One file shared into the app (e.g. a Google Phone recording), already
/// copied by the Kotlin bridge into app-private cache.
class SharedFilePayload {
  const SharedFilePayload({
    required this.id,
    required this.receivedAt,
    this.cachePath,
    this.displayName,
    this.mimeType,
    this.sizeBytes,
    this.sharedText,
    this.error,
  });

  factory SharedFilePayload.fromMap(Map<Object?, Object?> map) {
    return SharedFilePayload(
      id: map['id']! as String,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        map['receivedAt']! as int,
        isUtc: true,
      ),
      cachePath: map['cachePath'] as String?,
      displayName: map['displayName'] as String?,
      mimeType: map['mimeType'] as String?,
      sizeBytes: map['sizeBytes'] as int?,
      sharedText: map['sharedText'] as String?,
      error: map['error'] as String?,
    );
  }

  final String id;
  final DateTime receivedAt;

  /// Absolute path of the cached copy. Null when the copy failed.
  final String? cachePath;
  final String? displayName;
  final String? mimeType;
  final int? sizeBytes;
  final String? sharedText;

  /// Why the copy failed (unreadable URI, too large, low storage, ...).
  final String? error;

  bool get isFailed => error != null;
}

/// Dart side of the Kotlin share bridge in `MainActivity.kt`.
///
/// Kotlin keeps received shares in a queue until Dart takes them, so a
/// cold-start share is never lost. The event channel only signals that the
/// queue has new items; Dart then calls [takePending].
class ShareBridge {
  const ShareBridge();

  static const _methods = MethodChannel('lead_tracker/share');
  static const _events = EventChannel('lead_tracker/share/events');

  /// Returns and clears every queued share.
  Future<List<SharedFilePayload>> takePending() async {
    final raw = await _methods.invokeListMethod<Object?>('takePending');
    return [
      for (final item in raw ?? const <Object?>[])
        SharedFilePayload.fromMap(item! as Map<Object?, Object?>),
    ];
  }

  /// Deletes a cached copy. Kotlin refuses paths outside its share cache.
  Future<void> deleteCached(String cachePath) async {
    await _methods.invokeMethod<void>('deleteCached', {'path': cachePath});
  }

  /// Fires whenever new shares are queued while the app is running.
  Stream<void> get onSharesQueued =>
      _events.receiveBroadcastStream().map((_) {});
}

@Riverpod(keepAlive: true)
ShareBridge shareBridge(Ref ref) => const ShareBridge();
