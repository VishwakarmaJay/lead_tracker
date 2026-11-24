import 'package:flutter/material.dart';

/// Keys in the `app_settings` table.
enum AppSettingKey {
  defaultRegion('default_region'),
  defaultCountryCallingCode('default_country_calling_code'),
  lastCallHistorySyncAt('last_call_history_sync_at'),
  callHistorySyncEnabled('call_history_sync_enabled'),
  notificationEnabled('notification_enabled'),
  themeMode('theme_mode');

  const AppSettingKey(this.key);

  final String key;
}

/// Typed view of `app_settings`. Missing or unreadable values fall back to the
/// defaults, so a bad row never blocks startup.
@immutable
class AppSettings {
  const AppSettings({
    this.defaultRegion = 'IN',
    this.defaultCountryCallingCode = '+91',
    this.callHistorySyncEnabled = false,
    this.notificationEnabled = false,
    this.themeMode = ThemeMode.system,
    this.lastCallHistorySyncAt,
  });

  factory AppSettings.fromRaw(Map<String, String?> raw) {
    const defaults = AppSettings();
    String text(AppSettingKey key, String fallback) {
      final value = raw[key.key]?.trim();
      return value == null || value.isEmpty ? fallback : value;
    }

    bool flag(AppSettingKey key, {required bool fallback}) =>
        switch (raw[key.key]) {
          'true' => true,
          'false' => false,
          _ => fallback,
        };

    final lastSync = int.tryParse(
      raw[AppSettingKey.lastCallHistorySyncAt.key] ?? '',
    );
    return AppSettings(
      defaultRegion: text(AppSettingKey.defaultRegion, defaults.defaultRegion),
      defaultCountryCallingCode: text(
        AppSettingKey.defaultCountryCallingCode,
        defaults.defaultCountryCallingCode,
      ),
      callHistorySyncEnabled: flag(
        AppSettingKey.callHistorySyncEnabled,
        fallback: defaults.callHistorySyncEnabled,
      ),
      notificationEnabled: flag(
        AppSettingKey.notificationEnabled,
        fallback: defaults.notificationEnabled,
      ),
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == raw[AppSettingKey.themeMode.key],
        orElse: () => defaults.themeMode,
      ),
      lastCallHistorySyncAt: lastSync == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastSync, isUtc: true),
    );
  }

  final String defaultRegion;
  final String defaultCountryCallingCode;
  final bool callHistorySyncEnabled;
  final bool notificationEnabled;
  final ThemeMode themeMode;
  final DateTime? lastCallHistorySyncAt;

  AppSettings copyWith({ThemeMode? themeMode}) {
    return AppSettings(
      defaultRegion: defaultRegion,
      defaultCountryCallingCode: defaultCountryCallingCode,
      callHistorySyncEnabled: callHistorySyncEnabled,
      notificationEnabled: notificationEnabled,
      themeMode: themeMode ?? this.themeMode,
      lastCallHistorySyncAt: lastCallHistorySyncAt,
    );
  }
}
