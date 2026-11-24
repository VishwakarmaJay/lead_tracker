import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/instances/app_database_instance.dart';
import 'package:lead_tracker/src/settings/providers/settings_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_database.dart';

/// A provider container on a fresh test database, started like the app
/// (database open, settings loaded).
Future<(ProviderContainer, Database)> createTestContainer({
  List<Override> overrides = const [],
}) async {
  final db = await openTestDatabase();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((ref) async => db),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await container.read(appDatabaseProvider.future);
  await container.read(settingsProvider.future);
  return (container, db);
}
