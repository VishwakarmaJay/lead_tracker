import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_picker_service.g.dart';

/// A file the user chose, read into memory.
@immutable
class PickedFile {
  const PickedFile({required this.name, required this.bytes});

  /// Display name only — never used as a path.
  final String name;
  final Uint8List bytes;
}

/// Wraps `file_picker` so features (and tests) don't call the plugin directly.
class FilePickerService {
  const FilePickerService();

  static const maxSpreadsheetBytes = 20 * 1024 * 1024;

  /// Lets the user pick one `.xlsx` or `.csv` file. Returns null if cancelled.
  /// The picker's temporary copy is deleted once the bytes are read.
  Future<PickedFile?> pickSpreadsheet() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'csv'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null) {
      return null;
    }
    try {
      if (file.size > maxSpreadsheetBytes) {
        throw AppException(
          message: 'This file is larger than 20 MB.',
          type: ErrorType.file,
        );
      }
      final path = file.path;
      final bytes =
          file.bytes ?? (path == null ? null : await File(path).readAsBytes());
      if (bytes == null || bytes.isEmpty) {
        throw AppException(
          message: 'The file could not be read, or it is empty.',
          type: ErrorType.file,
        );
      }
      return PickedFile(name: file.name, bytes: bytes);
    } finally {
      try {
        await FilePicker.clearTemporaryFiles();
      } on Exception catch (e) {
        'Could not clear picker cache: ${e.runtimeType}'.logWarning();
      }
    }
  }
}

@riverpod
FilePickerService filePickerService(Ref ref) => const FilePickerService();
