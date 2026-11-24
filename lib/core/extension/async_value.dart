import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/src/shared/components/app_error.dart';
import 'package:lead_tracker/src/shared/components/app_loader.dart';

/// Renders loading / error / data for an [AsyncValue] (hedged's `unfold`).
///
/// While a provider refreshes (e.g. a new search), the previous data stays on
/// screen instead of flashing a loader.
extension AsyncValueUnfold<T> on AsyncValue<T> {
  Widget unfold(Widget Function(T value) builder, {VoidCallback? onRetry}) {
    if (hasError && !isLoading) {
      final error = this.error;
      return AppError(
        message: switch (error) {
          AppException(:final message) => message,
          _ => kDebugMode ? '$error\n$stackTrace' : 'Something went wrong.',
        },
        onRetry: onRetry,
      );
    }
    if (hasValue) {
      return builder(requireValue);
    }
    return const AppLoader();
  }
}
