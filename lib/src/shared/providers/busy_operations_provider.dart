import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'busy_operations_provider.g.dart';

/// Counts long-running operations (imports, recording copies, database
/// transactions) that must not be interrupted.
///
/// The update banner disables **Restart now** while this is above zero.
@Riverpod(keepAlive: true)
class BusyOperations extends _$BusyOperations {
  @override
  int build() => 0;

  /// Runs [operation] while marked as busy.
  Future<T> track<T>(Future<T> Function() operation) async {
    state = state + 1;
    try {
      return await operation();
    } finally {
      state = state - 1;
    }
  }
}
