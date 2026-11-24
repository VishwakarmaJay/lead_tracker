import 'dart:async';

import 'package:lead_tracker/core/extension/future.dart';
import 'package:lead_tracker/core/extension/log.dart';
import 'package:lead_tracker/core/instances/share_bridge.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_inbox_provider.g.dart';

/// Files shared into the app that the user hasn't handled yet.
///
/// Milestone 0 proof-of-concept: shows what Google Phone actually sends.
/// Milestone 4 replaces "discard" with the real import flow.
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

  /// Moves every queued share from Kotlin into this inbox.
  Future<void> pull() async {
    try {
      final received = await ref
          .read(shareBridgeProvider)
          .takePending()
          .guard();
      if (received.isNotEmpty) {
        state = [...state, ...received];
      }
    } on Exception catch (e) {
      'Could not read shared files: $e'.logError();
    }
  }

  /// Removes an item and deletes its cached copy.
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
