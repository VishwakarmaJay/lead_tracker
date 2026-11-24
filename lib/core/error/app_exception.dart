/// Where a failure came from. Drives how the UI reacts (retry, explain a
/// permission, offer cleanup, ...).
enum ErrorType { database, file, permission, parse, platform, other }

/// The single error type features catch. Produced by `Future.guard()`.
class AppException implements Exception {
  AppException({required this.message, required this.type, this.data});

  /// User-safe message. Never contains phone numbers, notes, or file paths.
  final String message;
  final ErrorType type;

  /// Optional extra detail for debugging (never shown in release builds).
  final Object? data;

  @override
  String toString() => 'AppException($type): $message';
}
