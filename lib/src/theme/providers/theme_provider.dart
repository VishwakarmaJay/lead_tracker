import 'package:flutter/material.dart';
import 'package:lead_tracker/core/extension/log.dart';
import 'package:lead_tracker/src/settings/providers/settings_provider.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

/// Light / dark / system mode, persisted in `app_settings.theme_mode`.
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() =>
      ref.watch(settingsProvider).value?.themeMode ?? ThemeMode.system;

  Future<void> select(ThemeMode mode) async {
    try {
      await ref.read(settingsProvider.notifier).setThemeMode(mode);
    } on Exception catch (e) {
      'Saving theme failed: $e'.logError();
      'Could not save the theme.'.showSnackBar();
    }
  }
}
