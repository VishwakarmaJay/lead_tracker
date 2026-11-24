import 'package:flutter/material.dart';

/// App color tokens, read through `context.colors`.
///
/// Material's [ColorScheme] covers standard surfaces; these tokens add the
/// app-specific meanings (lead temperature, success/warning) so widgets never
/// hard-code colors.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
    required this.text,
    required this.mutedText,
    required this.success,
    required this.warning,
    required this.danger,
    required this.hot,
    required this.warm,
    required this.cold,
  });

  static const light = AppColors(
    primary: Color(0xFF3949AB),
    onPrimary: Color(0xFFFFFFFF),
    background: Color(0xFFF7F7FA),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE2E3EA),
    text: Color(0xFF1B1C22),
    mutedText: Color(0xFF61636E),
    success: Color(0xFF2E7D32),
    warning: Color(0xFFB26A00),
    danger: Color(0xFFC62828),
    hot: Color(0xFFD84315),
    warm: Color(0xFFF9A825),
    cold: Color(0xFF1E88E5),
  );

  static const dark = AppColors(
    primary: Color(0xFF9FA8DA),
    onPrimary: Color(0xFF131A4A),
    background: Color(0xFF121318),
    surface: Color(0xFF1B1C22),
    card: Color(0xFF22232B),
    border: Color(0xFF34353F),
    text: Color(0xFFE6E6EE),
    mutedText: Color(0xFFA3A4B0),
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    danger: Color(0xFFEF9A9A),
    hot: Color(0xFFFF8A65),
    warm: Color(0xFFFFD54F),
    cold: Color(0xFF64B5F6),
  );

  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color card;
  final Color border;
  final Color text;
  final Color mutedText;
  final Color success;
  final Color warning;
  final Color danger;
  final Color hot;
  final Color warm;
  final Color cold;

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? background,
    Color? surface,
    Color? card,
    Color? border,
    Color? text,
    Color? mutedText,
    Color? success,
    Color? warning,
    Color? danger,
    Color? hot,
    Color? warm,
    Color? cold,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      border: border ?? this.border,
      text: text ?? this.text,
      mutedText: mutedText ?? this.mutedText,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      hot: hot ?? this.hot,
      warm: warm ?? this.warm,
      cold: cold ?? this.cold,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      card: mix(card, other.card),
      border: mix(border, other.border),
      text: mix(text, other.text),
      mutedText: mix(mutedText, other.mutedText),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      hot: mix(hot, other.hot),
      warm: mix(warm, other.warm),
      cold: mix(cold, other.cold),
    );
  }
}
