import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/core/instances/share_bridge.dart';
import 'package:lead_tracker/src/recordings/providers/shared_inbox_provider.dart';
import 'package:lead_tracker/src/shared/components/app_confirmation.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';

/// Milestone 0 proof-of-concept screen: shows exactly what was shared in
/// (name, MIME type, size, cache path) so the Google Phone payload can be
/// checked on the real device. Milestone 4 replaces it with the import flow.
@RoutePage()
class SharedInboxPage extends ConsumerWidget {
  const SharedInboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(sharedInboxProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Shared files')),
      body: items.isEmpty
          ? const AppEmptyWidget(
              icon: Icons.ios_share,
              title: 'Nothing shared yet',
              message:
                  'In Google Phone, open a recorded call, tap Share, '
                  'and pick Lead Tracker.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _SharedFileCard(key: ValueKey(item.id), item: item);
              },
            ),
    );
  }
}

class _SharedFileCard extends ConsumerWidget {
  const _SharedFileCard({required this.item, super.key});

  final SharedFilePayload item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = item.isFailed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  failed ? Icons.error_outline : Icons.audio_file_outlined,
                  color: failed
                      ? context.colors.danger
                      : context.colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.displayName ?? 'Unnamed file',
                    style: context.text.label,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (failed) _Field('Error', item.error!),
            _Field('MIME type', item.mimeType ?? 'unknown'),
            _Field('Size', _formatBytes(item.sizeBytes)),
            _Field('Received', item.receivedAt.toLocal().toString()),
            if (item.sharedText != null)
              _Field('Shared text', item.sharedText!),
            if (item.cachePath != null) _Field('Cache path', item.cachePath!),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Discard'),
                onPressed: () async {
                  final confirmed = await showAppConfirmation(
                    context,
                    title: 'Discard this file?',
                    message:
                        'The copy in Lead Tracker is deleted. The '
                        'original recording in Google Phone is not touched.',
                    confirmLabel: 'Discard',
                    destructive: true,
                  );
                  if (confirmed) {
                    await ref.read(sharedInboxProvider.notifier).discard(item);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatBytes(int? bytes) {
    if (bytes == null) {
      return 'unknown';
    }
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: context.text.caption)),
          Expanded(child: SelectableText(value, style: context.text.body)),
        ],
      ),
    );
  }
}
