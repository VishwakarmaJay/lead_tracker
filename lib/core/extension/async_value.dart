import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/src/shared/components/app_error.dart';
import 'package:lead_tracker/src/shared/components/app_loader.dart';

/// Renders loading / error / data for an [AsyncValue] (hedged's `unfold`).
extension AsyncValueUnfold<T> on AsyncValue<T> {
  Widget unfold(Widget Function(T value) builder, {VoidCallback? onRetry}) {
    return switch (this) {
      AsyncValue(:final T value, hasValue: true, isLoading: false) => builder(
        value,
      ),
      AsyncError(:final AppException error) => AppError(
        message: error.message,
        onRetry: onRetry,
      ),
      AsyncError(:final error, :final stackTrace) => AppError(
        message: kDebugMode ? '$error\n$stackTrace' : 'Something went wrong.',
        onRetry: onRetry,
      ),
      _ => const AppLoader(),
    };
  }
}
