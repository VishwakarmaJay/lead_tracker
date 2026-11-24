import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/log.dart';

/// Converts any failure into an [AppException] (hedged's `.guard()`, adapted
/// for local database, file, and platform-channel errors).
extension FutureGuard<T> on Future<T> {
  Future<T> guard() async {
    try {
      return await this;
    } on AppException {
      rethrow;
    } on FileSystemException catch (e) {
      'FileSystemException: ${e.message} (os: ${e.osError?.errorCode})'
          .logError();
      throw AppException(
        message: 'Could not read or write the file.',
        type: ErrorType.file,
        data: kDebugMode ? e : null,
      );
    } on PlatformException catch (e) {
      'PlatformException: ${e.code}'.logError();
      final isPermission = e.code.toLowerCase().contains('permission');
      throw AppException(
        message: isPermission
            ? 'Permission is needed to do this.'
            : e.message ?? 'Something went wrong on the device.',
        type: isPermission ? ErrorType.permission : ErrorType.platform,
        data: kDebugMode ? e : null,
      );
    } on FormatException catch (e) {
      'FormatException: ${e.message}'.logError();
      throw AppException(
        message: 'The file is not in the expected format.',
        type: ErrorType.parse,
        data: kDebugMode ? e : null,
      );
    } on Exception catch (e, stack) {
      // Milestone 1 adds an `on DatabaseException` branch (ErrorType.database)
      // above this one when sqflite becomes a dependency.
      '$e\n$stack'.logError();
      throw AppException(
        message: 'Something went wrong.',
        type: ErrorType.other,
        data: kDebugMode ? e : null,
      );
    }
  }
}
