import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/async_value.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/core/utils/formatters.dart';
import 'package:lead_tracker/src/leads/providers/lead_detail_provider.dart';
import 'package:lead_tracker/src/recordings/data/models/call_recording.dart';
import 'package:lead_tracker/src/recordings/providers/recording_detail_provider.dart';
import 'package:lead_tracker/src/recordings/ui/components/call_choice_list.dart';
import 'package:lead_tracker/src/recordings/ui/components/recording_player.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:lead_tracker/src/shared/components/app_confirmation.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';
import 'package:lead_tracker/src/shared/components/app_loader.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';

@RoutePage()
class RecordingPlayerPage extends ConsumerWidget {
  const RecordingPlayerPage({
    @PathParam('id') required this.recordingId,
    super.key,
  });

  final int recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recording = ref.watch(recordingDetailProvider(recordingId));
    final current = recording.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording'),
        actions: [
          if (current != null)
            IconButton(
              tooltip: 'Delete recording',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref),
            ),
        ],
      ),
      body: recording.unfold(
        (recording) => recording == null
            ? const AppEmptyWidget(
                icon: Icons.graphic_eq,
                title: 'This recording was deleted',
              )
            : _PlayerBody(recording: recording),
        onRetry: () => ref.invalidate(recordingDetailProvider(recordingId)),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmation(
      context,
      title: 'Delete this recording?',
      message:
          "Lead Tracker's copy is deleted. The original in Google "
          'Phone is not touched.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await ref.read(recordingDetailProvider(recordingId).notifier).delete();
      if (context.mounted) {
        await context.router.maybePop();
      }
      'Recording deleted'.showSnackBar();
    } on AppException catch (e) {
      e.message.showSnackBar();
    }
  }
}

class _PlayerBody extends ConsumerWidget {
  const _PlayerBody({required this.recording});

  final CallRecording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(recordingDetailProvider(recording.id).notifier);
    final file = ref.watch(recordingFileProvider(recording.relativePath));
    final lead = ref.watch(leadDetailProvider(recording.leadId)).value;

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } on AppException catch (e) {
        e.message.showSnackBar();
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: switch (file) {
              AsyncData(:final value) when value.existsSync() =>
                RecordingPlayer(
                  path: value.path,
                  onDuration: (duration) =>
                      run(() => notifier.saveDuration(duration)),
                ),
              AsyncData() => Text(
                'The audio file is missing from this phone.',
                style: context.text.body.copyWith(color: context.colors.danger),
              ),
              _ => const SizedBox(height: 48, child: AppLoader()),
            },
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: Text(lead?.name ?? 'Deleted lead'),
          subtitle: const Text('Lead'),
          trailing: lead == null ? null : const Icon(Icons.chevron_right),
          onTap: lead == null
              ? null
              : () => context.router.push(LeadDetailRoute(leadId: lead.id)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_outlined),
          title: Text(formatDateTime(recording.importedAt)),
          subtitle: Text(
            recording.importSource == RecordingImportSource.googlePhoneShare
                ? 'Saved from Google Phone'
                : 'Saved from a file',
          ),
        ),
        if (recording.originalFilename != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(recording.originalFilename!),
            subtitle: Text(
              '${(recording.fileSizeBytes / 1024).toStringAsFixed(0)} KB · '
              '${recording.mimeType}',
            ),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notes),
          title: Text(recording.notes ?? 'Add notes'),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () async {
            final notes = await _editNotes(context, recording.notes);
            if (notes != null) {
              await run(() => notifier.updateNotes(notes));
            }
          },
        ),
        const SizedBox(height: 16),
        Text('Linked call', style: context.text.subtitle),
        CallChoiceList(
          leadId: recording.leadId,
          selectedCallId: recording.callLogId,
          onChanged: (id) => run(() => notifier.linkToCall(id)),
        ),
      ],
    );
  }

  /// Returns the new text, or null if cancelled.
  static Future<String?> _editNotes(BuildContext context, String? current) {
    return showDialog<String>(
      context: context,
      builder: (_) => _NotesDialog(initial: current ?? ''),
    );
  }
}

/// Owns its text controller so it is disposed after the dialog's closing
/// animation, not during it.
class _NotesDialog extends StatefulWidget {
  const _NotesDialog({required this.initial});

  final String initial;

  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notes'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
