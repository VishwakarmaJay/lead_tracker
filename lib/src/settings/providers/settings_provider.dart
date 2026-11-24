import 'package:flutter/material.dart';
import 'package:lead_tracker/src/settings/data/models/app_settings.dart';
import 'package:lead_tracker/src/settings/data/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

/// App settings for the session, loaded during startup.
@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  Future<AppSettings> build() =>
      ref.watch(settingsRepositoryProvider).readAll();

  Future<void> setThemeMode(ThemeMode mode) async {
    final previous = state.value ?? const AppSettings();
    // Optimistic: the theme switches immediately.
    state = AsyncData(previous.copyWith(themeMode: mode));
    try {
      await ref
          .read(settingsRepositoryProvider)
          .write(AppSettingKey.themeMode, mode.name);
    } on Exception {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
