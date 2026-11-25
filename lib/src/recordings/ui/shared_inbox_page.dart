import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/core/instances/file_picker_service.dart';
import 'package:lead_tracker/core/instances/share_bridge.dart';
import 'package:lead_tracker/core/utils/formatters.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';
import 'package:lead_tracker/src/recordings/data/models/pending_recording.dart';
import 'package:lead_tracker/src/recordings/providers/shared_inbox_provider.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:lead_tracker/src/shared/components/app_confirmation.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';

/// Recordings shared into the app that still need a lead. They stay here —
/// even after the app is closed — until saved or discarded.
@RoutePage()
class SharedInboxPage extends ConsumerWidget {
  const SharedInboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(sharedInboxProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Shared recordings')),
      body: items.isEmpty
          ? AppEmptyWidget(
              icon: Icons.ios_share,
              title: 'Nothing waiting',
              message:
                  'In Google Phone, open a recorded call, tap Share, and '
                  'pick Lead Tracker. Or pick an audio file from your phone.',
              action: OutlinedButton.icon(
                onPressed: () => pickAudioAndImport(context, ref),
                icon: const Icon(Icons.audio_file_outlined),
                label: const Text('Pick an audio file'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _SharedItemCard(key: ValueKey(item.id), item: item);
              },
            ),
    );
  }
}

/// File-picker fallback: pick an audio file, then open the save screen.
/// Public: also used by the lead detail screen's "Add recording".
Future<void> pickAudioAndImport(
  BuildContext context,
  WidgetRef ref, {
  int? leadId,
}) async {
  final router = context.router;
  try {
    final picked = await ref.read(filePickerServiceProvider).pickAudio();
    if (picked == null) {
      return;
    }
    await router.push(
      RecordingImportRoute(
        recording: PendingRecording(
          path: picked.path,
          origin: RecordingImportSource.filePicker,
          displayName: picked.name,
          sizeBytes: picked.size,
        ),
        initialLeadId: leadId,
      ),
    );
  } on AppException catch (e) {
    e.message.showSnackBar();
  } on Exception {
    'The file picker could not open.'.showSnackBar();
  }
}

class _SharedItemCard extends ConsumerWidget {
  const _SharedItemCard({required this.item, super.key});

  final SharedFilePayload item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = item.isFailed;
    final details = [
      'Shared ${formatDateTime(item.receivedAt)}',
      if (item.sizeBytes != null) _formatSize(item.sizeBytes!),
      if (item.mimeType != null) item.mimeType!,
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
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
                    item.displayName ?? 'Shared recording',
                    style: context.text.label,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(details, style: context.text.caption),
            if (failed) ...[
              const SizedBox(height: 6),
              Text(
                item.error!,
                style: context.text.body.copyWith(color: context.colors.danger),
              ),
            ],
            if (kDebugMode && item.cachePath != null) ...[
              const SizedBox(height: 6),
              SelectableText(item.cachePath!, style: context.text.caption),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _discard(context, ref),
                  child: Text(failed ? 'Dismiss' : 'Discard'),
                ),
                if (!failed) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => context.router.push(
                      RecordingImportRoute(
                        recording: PendingRecording.fromShare(item),
                      ),
                    ),
                    child: const Text('Save to a lead'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    if (!item.isFailed) {
      final confirmed = await showAppConfirmation(
        context,
        title: 'Discard this recording?',
        message:
            "Lead Tracker's copy is deleted. The original in Google "
            'Phone is not touched.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!confirmed) {
        return;
      }
    }
    try {
      await ref.read(sharedInboxProvider.notifier).discard(item);
    } on AppException catch (e) {
      e.message.showSnackBar();
    }
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
