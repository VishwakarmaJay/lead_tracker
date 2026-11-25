import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/instances/share_bridge.dart';
import 'package:lead_tracker/src/recordings/providers/shared_inbox_provider.dart';

SharedFilePayload _item(
  String id, {
  int at = 0,
  String? path,
  String? name,
  String? error,
}) {
  return SharedFilePayload(
    id: id,
    receivedAt: DateTime.fromMillisecondsSinceEpoch(at, isUtc: true),
    cachePath: error == null ? (path ?? '/inbox/$id.m4a') : null,
    displayName: name,
    error: error,
  );
}

Map<String, Object?> _map(SharedFilePayload item) => {
  'id': item.id,
  'receivedAt': item.receivedAt.millisecondsSinceEpoch,
  'cachePath': item.cachePath,
  'displayName': item.displayName,
  'error': item.error,
};

void main() {
  group('mergeInbox', () {
    test('files come from disk, with richer details from new shares', () {
      final merged = mergeInbox(
        current: const [],
        fresh: [_item('b', at: 2, name: 'Call with Asha.m4a')],
        stored: [_item('a', at: 1), _item('b', at: 2)],
      );
      expect(merged.map((i) => i.id), ['a', 'b']);
      expect(merged.last.displayName, 'Call with Asha.m4a');
    });

    test('items no longer on disk drop out; failures are kept', () {
      final merged = mergeInbox(
        current: [
          _item('gone', at: 1),
          _item('f1', at: 2, error: 'expired'),
        ],
        fresh: [_item('f2', at: 3, error: 'too large')],
        stored: [_item('kept')],
      );
      expect(merged.map((i) => i.id), ['kept', 'f1', 'f2']);
    });
  });

  test('pull reads new shares and the stored inbox; discard deletes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const methods = MethodChannel('lead_tracker/share');
    const events = MethodChannel('lead_tracker/share/events');
    final deleted = <String>[];
    var stored = [_item('a', at: 1), _item('b', at: 2)];

    messenger
      ..setMockMethodCallHandler(methods, (call) async {
        switch (call.method) {
          case 'takePending':
            return [_map(_item('x', at: 3, error: 'Permission expired'))];
          case 'listCached':
            return stored.map(_map).toList();
          case 'deleteCached':
            final path = (call.arguments as Map)['path'] as String;
            deleted.add(path);
            stored = stored.where((i) => i.cachePath != path).toList();
            return true;
        }
        return null;
      })
      ..setMockMethodCallHandler(events, (call) async => null);
    addTearDown(() {
      messenger
        ..setMockMethodCallHandler(methods, null)
        ..setMockMethodCallHandler(events, null);
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final inbox = container.read(sharedInboxProvider.notifier);

    await inbox.pull();
    expect(container.read(sharedInboxProvider).map((i) => i.id), [
      'a',
      'b',
      'x',
    ]);

    await inbox.discard(container.read(sharedInboxProvider).first);
    expect(deleted, ['/inbox/a.m4a']);
    expect(container.read(sharedInboxProvider).map((i) => i.id), ['b', 'x']);

    // A failed share has no file: dismissing it calls nothing native.
    await inbox.discard(container.read(sharedInboxProvider).last);
    expect(deleted, hasLength(1));
  });
}
