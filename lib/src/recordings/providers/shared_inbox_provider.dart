import 'dart:async';

import 'package:lead_tracker/core/extension/future.dart';
import 'package:lead_tracker/core/extension/log.dart';
import 'package:lead_tracker/core/instances/share_bridge.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_inbox_provider.g.dart';

/// Recordings shared into the app that haven't been imported or discarded.
///
/// The Kotlin inbox on disk is the source of truth for successful shares, so
/// they survive the app being closed. Failed shares (no file) only live here
/// until the user dismisses them.
///
/// keepAlive: it owns the share-event subscription for the whole session, so
/// a share arriving while no screen watches it is still collected.
@Riverpod(keepAlive: true)
class SharedInbox extends _$SharedInbox {
  @override
  List<SharedFilePayload> build() {
    final subscription = ref
        .read(shareBridgeProvider)
        .onSharesQueued
        .listen((_) => unawaited(pull()));
    ref.onDispose(subscription.cancel);
    return const [];
  }

  /// Reads new shares and everything still on disk, oldest first.
  Future<void> pull() async {
    final bridge = ref.read(shareBridgeProvider);
    try {
      final fresh = await bridge.takePending().guard();
      final stored = await bridge.listCached().guard();
      state = mergeInbox(current: state, fresh: fresh, stored: stored);
    } on Exception catch (e) {
      'Could not read shared files: $e'.logError();
    }
  }

  /// Deletes the copy (if any) and removes the item.
  Future<void> discard(SharedFilePayload item) async {
    final path = item.cachePath;
    if (path != null) {
      await ref.read(shareBridgeProvider).deleteCached(path).guard();
    }
    state = [
      for (final other in state)
        if (other.id != item.id) other,
    ];
  }
}

/// Merges inbox sources:
/// - successful shares come from [stored] (what is really on disk), using the
///   richer metadata from [fresh] when the same id is in both;
/// - failed shares (no file) are kept from [current] and added from [fresh].
List<SharedFilePayload> mergeInbox({
  required List<SharedFilePayload> current,
  required List<SharedFilePayload> fresh,
  required List<SharedFilePayload> stored,
}) {
  final freshById = {for (final item in fresh) item.id: item};
  final failures = [
    ...current.where((item) => item.isFailed),
    ...fresh.where((item) => item.isFailed),
  ];
  final files = [for (final item in stored) freshById[item.id] ?? item];
  return [...files, ...failures]
    ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
}
