import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/core/instances/app_database_instance.dart';
import 'package:lead_tracker/src/settings/data/models/app_settings.dart';
import 'package:lead_tracker/src/settings/data/settings_repository.dart';
import 'package:lead_tracker/src/settings/providers/settings_provider.dart';
import 'package:lead_tracker/src/theme/providers/theme_provider.dart';

import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('repository reads the seeded defaults', () async {
    final repo = SettingsRepository(await openTestDatabase());
    final settings = await repo.readAll();
    expect(settings.defaultRegion, 'IN');
    expect(settings.defaultCountryCallingCode, '+91');
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.notificationEnabled, isFalse);
    expect(settings.callHistorySyncEnabled, isFalse);
    expect(settings.lastCallHistorySyncAt, isNull);
  });

  test('write replaces a value', () async {
    final repo = SettingsRepository(await openTestDatabase());
    await repo.write(AppSettingKey.themeMode, 'dark');
    expect(await repo.read(AppSettingKey.themeMode), 'dark');
    expect((await repo.readAll()).themeMode, ThemeMode.dark);
  });

  test('unreadable values fall back to defaults', () {
    final settings = AppSettings.fromRaw(const {
      'theme_mode': 'purple',
      'notification_enabled': 'yes',
      'default_country_calling_code': '  ',
      'last_call_history_sync_at': 'soon',
    });
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.notificationEnabled, isFalse);
    expect(settings.defaultCountryCallingCode, '+91');
    expect(settings.lastCallHistorySyncAt, isNull);
  });

  test('theme choice is persisted and survives a new session', () async {
    final testDb = await TestDatabase.create();
    final db = await testDb.open();

    final first = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
    );
    addTearDown(first.dispose);
    await first.read(appDatabaseProvider.future);
    await first.read(settingsProvider.future);
    expect(first.read(appThemeModeProvider), ThemeMode.system);

    await first.read(appThemeModeProvider.notifier).select(ThemeMode.dark);
    expect(first.read(appThemeModeProvider), ThemeMode.dark);

    final second = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
    );
    addTearDown(second.dispose);
    await second.read(appDatabaseProvider.future);
    await second.read(settingsProvider.future);
    expect(second.read(appThemeModeProvider), ThemeMode.dark);
  });
}
