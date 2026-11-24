import 'package:flutter/material.dart';
import 'package:lead_tracker/core/constants/keys.dart';

/// Shows a snack bar from anywhere (widgets or notifiers).
extension SnackBarExt on String {
  void showSnackBar({
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(this),
          duration: duration,
          action: actionLabel == null || onAction == null
              ? null
              : SnackBarAction(label: actionLabel, onPressed: onAction),
        ),
      );
  }
}
