import 'package:lead_tracker/src/recordings/providers/shared_inbox_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'startup_provider.g.dart';

/// Everything that must finish before the home tabs open.
///
/// Milestone 0: collect shares that arrived on a cold start.
/// Milestone 1 adds: open the database and run migrations.
/// Milestone 6 adds: initialise local notifications.
@Riverpod(keepAlive: true)
Future<void> startup(Ref ref) async {
  await ref.read(sharedInboxProvider.notifier).pull();
}
