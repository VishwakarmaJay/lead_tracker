import 'package:lead_tracker/core/instances/app_database_instance.dart';
import 'package:lead_tracker/src/recordings/providers/shared_inbox_provider.dart';
import 'package:lead_tracker/src/settings/providers/settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'startup_provider.g.dart';

/// Everything that must finish before the home tabs open.
///
/// 1. Open the database (creates or migrates it). Repositories rely on this.
/// 2. Load settings (theme, default country code).
/// 3. Collect shares that arrived on a cold start.
///
/// Milestone 6 adds: initialise local notifications.
@Riverpod(keepAlive: true)
Future<void> startup(Ref ref) async {
  await ref.read(appDatabaseProvider.future);
  await ref.read(settingsProvider.future);
  await ref.read(sharedInboxProvider.notifier).pull();
}
