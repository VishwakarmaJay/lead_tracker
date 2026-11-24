import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/shared/providers/busy_operations_provider.dart';
import 'package:lead_tracker/src/update/providers/patch_provider.dart';

/// Slim banner above the bottom navigation that walks the user through
/// applying a Shorebird patch. It never blocks the app.
class PatchBanner extends ConsumerWidget {
  const PatchBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(patchProvider).value ?? PatchStatus.hidden;
    if (status == PatchStatus.hidden) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(patchProvider.notifier);
    final readyToRestart = status == PatchStatus.readyToRestart;
    final downloading = status == PatchStatus.downloading;
    // Restarting mid-import would kill the copy or transaction.
    final busy = ref.watch(busyOperationsProvider.select((count) => count > 0));

    final String subtitle;
    if (readyToRestart) {
      subtitle = busy
          ? 'Finishing your import first. Restart will be available soon.'
          : 'Restart the app to apply the latest changes.';
    } else {
      subtitle = 'Get the latest improvements in one tap.';
    }

    final VoidCallback? onPressed;
    if (downloading || (readyToRestart && busy)) {
      onPressed = null;
    } else if (readyToRestart) {
      onPressed = notifier.restart;
    } else {
      onPressed = notifier.download;
    }

    return Material(
      color: context.colors.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            Icon(
              readyToRestart
                  ? Icons.check_circle_outline
                  : Icons.system_update_alt,
              color: context.colors.onPrimary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    readyToRestart
                        ? 'Update ready'
                        : 'A new update is available',
                    style: context.text.label.copyWith(
                      color: context.colors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.text.caption.copyWith(
                      color: context.colors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.onPrimary,
                foregroundColor: context.colors.primary,
                disabledBackgroundColor: context.colors.onPrimary.withValues(
                  alpha: 0.6,
                ),
              ),
              child: downloading
                  ? const _DownloadingLabel()
                  : Text(readyToRestart ? 'Restart now' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadingLabel extends StatelessWidget {
  const _DownloadingLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 14,
          width: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(width: 8),
        const Text('Downloading…'),
      ],
    );
  }
}
