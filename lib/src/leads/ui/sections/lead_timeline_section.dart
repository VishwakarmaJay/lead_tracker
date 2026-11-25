import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/async_value.dart';
import 'package:lead_tracker/src/calls/data/models/call_log.dart';
import 'package:lead_tracker/src/calls/ui/components/call_log_tile.dart';
import 'package:lead_tracker/src/calls/ui/components/log_call_sheet.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_timeline_provider.dart';
import 'package:lead_tracker/src/recordings/ui/components/recording_tile.dart';
import 'package:lead_tracker/src/shared/components/app_confirmation.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';

/// The lead's calls and recordings, newest first (a sliver).
class LeadTimelineSection extends ConsumerWidget {
  const LeadTimelineSection({required this.lead, super.key});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(leadTimelineProvider(lead.id));
    final entries = timeline.value;
    if (entries == null || (timeline.hasError && !timeline.isLoading)) {
      // Loading or error: unfold renders the loader / error box.
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 160,
          child: timeline.unfold(
            (_) => const SizedBox.shrink(),
            onRetry: () => ref.invalidate(leadTimelineProvider(lead.id)),
          ),
        ),
      );
    }
    if (entries.isEmpty) {
      return const SliverToBoxAdapter(
        child: AppEmptyWidget(
          icon: Icons.history,
          title: 'No activity yet',
          message:
              'Tap Call, then log what was discussed when you come back. '
              'Recordings you save show up here too.',
        ),
      );
    }
    return SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        TimelineRecording(:final recording, :final linkedCall) => RecordingTile(
          key: ValueKey('recording-${recording.id}'),
          recording: recording,
          linkedCallAt: linkedCall?.calledAt,
        ),
        TimelineCall(:final call, :final hasRecording) => CallLogTile(
          key: ValueKey('call-${call.id}'),
          call: call,
          onTap: () => _edit(context, call),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasRecording)
                const Tooltip(
                  message: 'Has a recording',
                  child: Icon(Icons.graphic_eq, size: 18),
                ),
              PopupMenuButton<String>(
                onSelected: (value) => value == 'delete'
                    ? _delete(context, ref, call)
                    : _edit(context, call),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      },
    );
  }

  void _edit(BuildContext context, CallLog call) {
    showLogCallSheet(
      context,
      leadId: lead.id,
      leadName: lead.name,
      existing: call,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CallLog call,
  ) async {
    final confirmed = await showAppConfirmation(
      context,
      title: 'Delete this call?',
      message:
          'The call and its summary are removed from Lead Tracker. A '
          'recording linked to it is kept.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref
          .read(leadTimelineProvider(lead.id).notifier)
          .deleteCall(call.id);
    } on AppException catch (e) {
      e.message.showSnackBar();
    }
  }
}
