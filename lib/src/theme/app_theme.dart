import 'package:flutter/material.dart';
import 'package:lead_tracker/src/theme/app_color.dart';
import 'package:lead_tracker/src/theme/app_text_theme.dart';

/// Builds the Material 3 light and dark themes with the app extensions.
ThemeData buildAppTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.light.primary,
        brightness: brightness,
      ).copyWith(
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        surface: colors.surface,
        error: colors.danger,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    dividerColor: colors.border,
    cardTheme: CardThemeData(
      color: colors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    extensions: [colors, AppTypography.fromColors(colors)],
  );
}
