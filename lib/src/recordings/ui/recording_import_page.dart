import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/core/utils/formatters.dart';
import 'package:lead_tracker/src/calls/providers/recent_calls_provider.dart';
import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_labels.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_picker_sheet.dart';
import 'package:lead_tracker/src/recordings/data/models/pending_recording.dart';
import 'package:lead_tracker/src/recordings/providers/recording_import_provider.dart';
import 'package:lead_tracker/src/recordings/services/recording_import_service.dart';
import 'package:lead_tracker/src/recordings/ui/components/call_choice_list.dart';
import 'package:lead_tracker/src/recordings/ui/components/recording_player.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';

/// Attach one pending recording to a lead. The user always picks the lead
/// themselves — the app never guesses from the file name. Recent calls are
/// offered as shortcuts, not as matches.
@RoutePage()
class RecordingImportPage extends ConsumerStatefulWidget {
  const RecordingImportPage({
    required this.recording,
    this.initialLeadId,
    super.key,
  });

  final PendingRecording recording;

  /// Set when opened from a lead's "Add recording".
  final int? initialLeadId;

  @override
  ConsumerState<RecordingImportPage> createState() =>
      _RecordingImportPageState();
}

class _RecordingImportPageState extends ConsumerState<RecordingImportPage> {
  Lead? _lead;
  int? _callLogId;
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final id = widget.initialLeadId;
    if (id != null) {
      _selectLeadById(id);
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _selectLeadById(int id) async {
    final lead = await ref.read(leadRepositoryProvider).getLeadById(id);
    if (lead != null && mounted) {
      setState(() {
        _lead = lead;
        _callLogId = null;
      });
    }
  }

  Future<void> _chooseLead() async {
    final lead = await showLeadPicker(context, title: 'Who is this call with?');
    if (lead != null && mounted) {
      setState(() {
        _lead = lead;
        _callLogId = null;
      });
    }
  }

  Future<void> _save() async {
    final lead = _lead;
    if (lead == null) {
      return;
    }
    final router = context.router;
    try {
      final result = await ref
          .read(recordingImportControllerProvider.notifier)
          .save(
            widget.recording,
            leadId: lead.id,
            callLogId: _callLogId,
            notes: _notes.text,
          );
      if (!mounted) {
        return;
      }
      switch (result) {
        case RecordingImported(:final playable):
          await router.maybePop();
          (playable
                  ? 'Recording saved to ${lead.name}'
                  : "Saved to ${lead.name}, but this phone can't play the file.")
              .showSnackBar(
                actionLabel: 'Open lead',
                onAction: () => router.push(LeadDetailRoute(leadId: lead.id)),
              );
        case RecordingAlreadyImported(:final existing):
          await _showDuplicate(
            existing.leadId,
            existing.importedAt,
            existing.id,
          );
      }
    } on AppException catch (e) {
      // The temporary copy is kept; the user can retry.
      e.message.showSnackBar();
    }
  }

  Future<void> _showDuplicate(
    int leadId,
    DateTime importedAt,
    int recordingId,
  ) async {
    final owner = await ref
        .read(leadRepositoryProvider)
        .getLeadById(leadId, includeDeleted: true);
    if (!mounted) {
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Already saved'),
        content: Text(
          'This exact recording was saved to ${owner?.name ?? 'a lead'} on '
          '${formatDateTime(importedAt)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Discard this copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('open'),
            child: const Text('Open it'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    final router = context.router;
    if (choice == 'discard') {
      await ref
          .read(recordingImportControllerProvider.notifier)
          .discardSource(widget.recording);
      await router.maybePop();
    } else if (choice == 'open') {
      await router.replace(RecordingPlayerRoute(recordingId: recordingId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(recordingImportControllerProvider);
    final lead = _lead;
    final file = widget.recording;
    final details = [
      if (file.sizeBytes != null) _formatSize(file.sizeBytes!),
      if (file.mimeType != null) file.mimeType!,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(title: const Text('Save recording')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.audio_file, color: context.colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          file.displayName ?? 'Shared recording',
                          style: context.text.label,
                        ),
                      ),
                    ],
                  ),
                  if (details.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 32),
                      child: Text(details, style: context.text.caption),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Listen to check who the call is with.',
                    style: context.text.caption,
                  ),
                  RecordingPlayer(path: file.path),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Who is this call with?', style: context.text.subtitle),
          const SizedBox(height: 8),
          if (lead != null)
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: LeadAvatar(lead: lead),
                title: Text(lead.name),
                subtitle: Text(
                  [lead.company, lead.phone].whereType<String>().join(' · '),
                ),
                trailing: TextButton(
                  onPressed: _chooseLead,
                  child: const Text('Change'),
                ),
              ),
            )
          else ...[
            OutlinedButton.icon(
              onPressed: _chooseLead,
              icon: const Icon(Icons.person_search),
              label: const Text('Choose lead'),
            ),
            _RecentCallLeads(onSelected: _selectLeadById),
          ],
          if (lead != null) ...[
            const SizedBox(height: 24),
            Text(
              'Link to a logged call (optional)',
              style: context.text.subtitle,
            ),
            CallChoiceList(
              leadId: lead.id,
              selectedCallId: _callLogId,
              onChanged: (id) => setState(() => _callLogId = id),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 96),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: lead == null || saving ? null : _save,
            child: Text(
              saving
                  ? 'Saving…'
                  : lead == null
                  ? 'Choose a lead to save'
                  : 'Save to ${lead.name}',
            ),
          ),
        ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Shortcuts to leads called in the last 24 hours. The user still chooses.
class _RecentCallLeads extends ConsumerWidget {
  const _RecentCallLeads({required this.onSelected});

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls = ref.watch(recentCallsProvider).value ?? const [];
    final since = DateTime.now().subtract(const Duration(hours: 24));
    final seen = <int>{};
    final recent = [
      for (final item in calls)
        if (item.call.leadId != null &&
            !item.leadDeleted &&
            item.call.calledAt.isAfter(since) &&
            seen.add(item.call.leadId!))
          item,
    ].take(3).toList();
    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Called recently', style: context.text.caption),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final item in recent)
                ActionChip(
                  avatar: const Icon(Icons.history, size: 18),
                  label: Text(
                    '${item.leadName ?? 'Lead'} · '
                    '${formatTime(item.call.calledAt)}',
                  ),
                  onPressed: () => onSelected(item.call.leadId!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
