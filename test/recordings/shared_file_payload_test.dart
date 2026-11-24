import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/instances/share_bridge.dart';

void main() {
  test('parses a successful share from the Kotlin bridge', () {
    final payload = SharedFilePayload.fromMap(const {
      'id': 'abc',
      'receivedAt': 1764000000000,
      'cachePath': '/data/user/0/app/cache/shared_imports/abc.m4a',
      'displayName': 'Call recording.m4a',
      'mimeType': 'audio/mp4',
      'sizeBytes': 123456,
      'sharedText': null,
      'error': null,
    });

    expect(payload.isFailed, isFalse);
    expect(payload.sizeBytes, 123456);
    expect(payload.receivedAt.isUtc, isTrue);
  });

  test('parses a failed share', () {
    final payload = SharedFilePayload.fromMap(const {
      'id': 'def',
      'receivedAt': 1764000000000,
      'cachePath': null,
      'error': 'Permission to read the file has expired. Share it again.',
    });

    expect(payload.isFailed, isTrue);
    expect(payload.cachePath, isNull);
  });
}
