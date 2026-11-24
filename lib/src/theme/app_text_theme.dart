import 'package:flutter/material.dart';
import 'package:lead_tracker/src/theme/app_color.dart';

/// Text styles, read through `context.text`. Restyle with `copyWith`.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.bodyMuted,
    required this.label,
    required this.caption,
  });

  factory AppTypography.fromColors(AppColors colors) {
    return AppTypography(
      title: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colors.text,
      ),
      subtitle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.text,
      ),
      body: TextStyle(fontSize: 14, color: colors.text),
      bodyMuted: TextStyle(fontSize: 14, color: colors.mutedText),
      label: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.text,
      ),
      caption: TextStyle(fontSize: 12, color: colors.mutedText),
    );
  }

  final TextStyle title;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle bodyMuted;
  final TextStyle label;
  final TextStyle caption;

  @override
  AppTypography copyWith({
    TextStyle? title,
    TextStyle? subtitle,
    TextStyle? body,
    TextStyle? bodyMuted,
    TextStyle? label,
    TextStyle? caption,
  }) {
    return AppTypography(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      body: body ?? this.body,
      bodyMuted: bodyMuted ?? this.bodyMuted,
      label: label ?? this.label,
      caption: caption ?? this.caption,
    );
  }

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other == null) {
      return this;
    }
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTypography(
      title: mix(title, other.title),
      subtitle: mix(subtitle, other.subtitle),
      body: mix(body, other.body),
      bodyMuted: mix(bodyMuted, other.bodyMuted),
      label: mix(label, other.label),
      caption: mix(caption, other.caption),
    );
  }
}
