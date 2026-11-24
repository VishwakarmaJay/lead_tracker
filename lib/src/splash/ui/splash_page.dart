import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/src/recordings/providers/shared_inbox_provider.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:lead_tracker/src/shared/components/app_error.dart';
import 'package:lead_tracker/src/shared/components/app_loader.dart';
import 'package:lead_tracker/src/splash/providers/startup_provider.dart';

/// Waits for [startupProvider], then opens the home tabs (and the shared
/// files screen on top if the app was launched by a share).
@RoutePage()
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(startupProvider, (_, next) {
      if (next is AsyncData) {
        final hasShares = ref.read(sharedInboxProvider).isNotEmpty;
        context.router.replaceAll([
          const HomeRoute(),
          if (hasShares) const SharedInboxRoute(),
        ]);
      }
    });

    final startup = ref.watch(startupProvider);
    return Scaffold(
      body: startup.hasError
          ? AppError(
              message: 'The app could not start.',
              onRetry: () => ref.invalidate(startupProvider),
            )
          : const AppLoader(),
    );
  }
}
