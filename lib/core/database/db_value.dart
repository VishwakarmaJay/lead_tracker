/// Helpers shared by the repositories: stable enum strings and UTC times.
library;

/// An enum stored as a stable string in SQLite. The Dart name can change; the
/// [dbValue] must not.
abstract interface class DbValue {
  String get dbValue;
}

/// Reads an enum from its stored string. Unknown values throw a
/// [FormatException], which `.guard()` reports as a parse error.
T enumFromDb<T extends DbValue>(List<T> values, Object? raw) {
  for (final value in values) {
    if (value.dbValue == raw) {
      return value;
    }
  }
  throw FormatException('Unknown stored value for $T: $raw');
}

T? enumFromDbOrNull<T extends DbValue>(List<T> values, Object? raw) =>
    raw == null ? null : enumFromDb(values, raw);

/// Timestamps are stored as UTC Unix milliseconds; convert to local time only
/// in the UI.
extension DbTime on DateTime {
  int toDb() => toUtc().millisecondsSinceEpoch;
}

DateTime dateFromDb(Object? millis) =>
    DateTime.fromMillisecondsSinceEpoch(millis! as int, isUtc: true);

DateTime? dateFromDbOrNull(Object? millis) =>
    millis == null ? null : dateFromDb(millis);
