import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lead_tracker/core/database/app_database.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/log.dart';
import 'package:sqflite/sqflite.dart';

/// Converts any failure into an [AppException] (hedged's `.guard()`, adapted
/// for local database, file, and platform-channel errors).
extension FutureGuard<T> on Future<T> {
  Future<T> guard() async {
    try {
      return await this;
    } on AppException {
      rethrow;
    } on DatabaseTooNewException catch (e) {
      '$e'.logError();
      throw AppException(
        message:
            'Your data was saved by a newer version of Lead Tracker. '
            'Install the latest release to open it.',
        type: ErrorType.database,
        data: e,
      );
    } on DatabaseException catch (e) {
      'DatabaseException (code ${e.getResultCode()})'.logError();
      throw AppException(
        message: _databaseMessage(e),
        type: ErrorType.database,
        data: kDebugMode ? e : null,
      );
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
      '$e\n$stack'.logError();
      throw AppException(
        message: 'Something went wrong.',
        type: ErrorType.other,
        data: kDebugMode ? e : null,
      );
    }
  }
}

String _databaseMessage(DatabaseException e) {
  final text = e.toString();
  if (e.isUniqueConstraintError()) {
    return 'This record already exists.';
  }
  if (text.contains('FOREIGN KEY constraint failed')) {
    return 'This record is still linked to other data.';
  }
  if (e.isNotNullConstraintError() ||
      text.contains('CHECK constraint failed')) {
    return 'Some required information is missing or invalid.';
  }
  return 'Could not save or load your data.';
}
