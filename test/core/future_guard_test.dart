import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/future.dart';

Matcher throwsAppException(ErrorType type) =>
    throwsA(isA<AppException>().having((e) => e.type, 'type', type));

void main() {
  group('Future.guard', () {
    test('returns the value on success', () async {
      expect(await Future.value(42).guard(), 42);
    });

    test('maps FileSystemException to ErrorType.file', () {
      expect(
        Future<void>.error(const FileSystemException('nope')).guard(),
        throwsAppException(ErrorType.file),
      );
    });

    test('maps PlatformException with a permission code to permission', () {
      expect(
        Future<void>.error(
          PlatformException(code: 'permission_denied'),
        ).guard(),
        throwsAppException(ErrorType.permission),
      );
    });

    test('maps other PlatformException to platform', () {
      expect(
        Future<void>.error(PlatformException(code: 'io')).guard(),
        throwsAppException(ErrorType.platform),
      );
    });

    test('maps FormatException to parse', () {
      expect(
        Future<void>.error(const FormatException('bad csv')).guard(),
        throwsAppException(ErrorType.parse),
      );
    });

    test('passes an AppException through unchanged', () {
      final original = AppException(message: 'x', type: ErrorType.database);
      expect(Future<void>.error(original).guard(), throwsA(same(original)));
    });

    test('maps anything else to other', () {
      expect(
        Future<void>.error(Exception('boom')).guard(),
        throwsAppException(ErrorType.other),
      );
    });
  });
}
