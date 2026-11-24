import 'package:flutter/material.dart';
import 'package:lead_tracker/src/theme/app_color.dart';
import 'package:lead_tracker/src/theme/app_text_theme.dart';

/// Theme access used everywhere instead of `Theme.of(context)`.
extension ContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);

  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  AppTypography get text =>
      Theme.of(this).extension<AppTypography>() ??
      AppTypography.fromColors(colors);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
