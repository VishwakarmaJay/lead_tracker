import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recording_storage.g.dart';

/// Where recordings live: `<app documents>/recordings/lead_<id>/<file>`.
///
/// The database stores the path **relative** to the documents directory, so
/// it stays valid if Android moves the app's data directory.
class RecordingStorage {
  RecordingStorage(this._documentsDirectory);

  final Future<Directory> Function() _documentsDirectory;
  Future<Directory>? _root;

  Future<Directory> _documents() => _root ??= _documentsDirectory();

  /// Absolute file for a stored relative path.
  Future<File> resolve(String relativePath) async {
    final documents = await _documents();
    return File(p.join(documents.path, relativePath));
  }

  /// Copies [source] to `recordings/lead_<leadId>/<storedFilename>` and
  /// returns the relative path. Streams the copy; the source is untouched.
  Future<String> copyIn({
    required File source,
    required int leadId,
    required String storedFilename,
  }) async {
    final relative = p.join('recordings', 'lead_$leadId', storedFilename);
    final target = await resolve(relative);
    await target.parent.create(recursive: true);
    final part = File('${target.path}.part');
    try {
      await source.openRead().pipe(part.openWrite());
      await part.rename(target.path);
    } on Object {
      if (part.existsSync()) {
        await part.delete();
      }
      rethrow;
    }
    return relative;
  }

  /// Deletes a stored file (no error if it is already gone).
  Future<void> delete(String relativePath) async {
    final file = await resolve(relativePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

@riverpod
RecordingStorage recordingStorage(Ref ref) =>
    RecordingStorage(getApplicationDocumentsDirectory);

/// SHA-256 of a file, hex-encoded. Streams the file in a background isolate,
/// so large recordings are never loaded into memory or block the UI.
Future<String> sha256OfFile(String path) {
  return Isolate.run(() async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString();
  });
}
